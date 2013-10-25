util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require '../../../lib/queue'

Fabricator = require '../../fabricator'
Utils = require '../../../lib/utils'
bbCallback = Utils.bbCallback

ModelCache = require('../../../lib/cache/singletons').ModelCache
QueryCache = require('../../../lib/cache/singletons').QueryCache

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: _.defaults({
      boolean: 'Boolean'
      owners: -> ['hasMany', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Flat)

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    @schema: _.defaults({
      owners: -> ['hasMany', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Reverse)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    @schema: _.defaults({
      reverses: -> ['hasMany', Reverse]
      flat: -> ['belongsTo', Flat]
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  describe "Query cache (cache: #{options.cache}, embed: #{options.embed})", ->

    before (done) -> return done() unless options.before; options.before([Reverse, Owner], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      relation = Owner.relation('reverses')
      delete relation.virtual
      MODELS = {}

      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure query cache
      queue.defer (callback) ->
        query_cache_options = _.extend({enabled: true, verbose: false}, options.query_cache_options or {})
        QueryCache.configure(query_cache_options).reset(callback) # configure query cache

      # destroy all
      queue.defer (callback) -> Utils.resetSchemas [Flat, Reverse, Owner], callback

      # create all
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flats_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverses_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owners_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err))

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.save {reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()], flat: MODELS.flat.pop()}, bbCallback callback

        save_queue.await callback

      # reset query cache
      queue.defer (callback) -> QueryCache.reset(callback) # Reset after models created

      queue.await ->
        QueryCache.verbose = false
        console.log '\n'
        done()

    it 'Can perform the same query twice with a cache hit the second time', (done) ->
      query = {$one: true}
      Flat.cursor(query).toJSON (err, flat) ->
        assert.ok(!err, "No errors: #{err}")

        assert.equal(1, QueryCache.misses, "One miss after one query, Expected: 1, Actual: #{QueryCache.misses}")
        assert.equal(0, QueryCache.hits, "No hits after one query")

        Flat.cursor(query).toJSON (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(1, QueryCache.misses, "No more misses after second query, Expected: 1, Actual: #{QueryCache.misses}")
          assert.equal(1, QueryCache.hits, "One hit after second query, Expected: 1, Actual: #{QueryCache.hits}")
          done()

    it 'Stores the correct models with the cache result for a query on one model', (done) ->
      query = {$one: true}
      QueryCache.verbose = true
      Flat.cursor(query).toJSON (err, flat) ->
        assert.ok(!err, "No errors: #{err}")

        QueryCache.get Flat, query, (err, result) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(result, "Query cache hit: #{result}")

          meta_key = QueryCache.cacheKeyMeta(Flat)
          QueryCache.getKey meta_key, (err, meta_result) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(meta_result, "Meta cache hit: #{meta_result}")

            query_key = QueryCache.cacheKey(Flat, query)
            assert.equal(1, meta_result.length, "Has one model stored for meta query, Expected: 1, Actual: #{meta_result.length}")
            assert.equal(query_key, meta_result[0], "Has the correct query stored for meta query, Expected: #{query_key}, Actual: #{meta_result[0]}")
            done()

    it 'Can perform the same query twice with a cache hit the second time with a many to many include', (done) ->
      query = {$one: true, $include: ['reverses']}
      Owner.cursor(query).toJSON (err, owner) ->
        assert.ok(!err, "No errors: #{err}")

        misses = QueryCache.misses
        assert.equal(0, QueryCache.hits, "No hits after one query")
        Owner.cursor(query).toJSON (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(misses, QueryCache.misses, "No more misses after second query, Expected: #{misses}, Actual: #{QueryCache.misses}")
          assert.notEqual(0, QueryCache.hits, "At least one hit after second query, Expected: >0, Actual: #{QueryCache.hits}")
          done()

    it 'Stores the correct models with the cache result with a many to many include', (done) ->
      query = {$one: true, $include: ['reverses']}
      Owner.cursor(query).toJSON (err, owner) ->
        assert.ifError(err, "No errors: #{err}")

        owner_key = QueryCache.cacheKeyMeta(Owner)
        reverse_key = QueryCache.cacheKeyMeta(Reverse)
        JoinTable = Owner.schema().relation('reverses').join_table
        join_table_key = QueryCache.cacheKeyMeta(JoinTable)
        query_key = QueryCache.cacheKey(Owner, query)
        queue = new Queue()

        for meta_key in [owner_key, reverse_key, join_table_key]
          queue.defer (callback) ->
            QueryCache.getKey meta_key, (err, meta_result) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(meta_result, "Cache hit: #{meta_result}")
              assert.ok(query_key in meta_result, "Contains the original query_key")
              callback()

        queue.await done

    it 'Clears the correct models with the cache result with a many to many include', (done) ->
      query = {$one: true, $include: ['reverses']}
      Owner.cursor(query).toJSON (err, owner) ->
        assert.ok(!err, "No errors: #{err}")

        misses = QueryCache.misses
        QueryCache.reset Owner, (err) ->
          assert.ok(!err, "No errors: #{err}")

          QueryCache.get Owner, query, (err, query_result) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(!query_result, "Query result should be undefined: #{query_result}")

            QueryCache.getMeta Owner, (err, meta_result) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!meta_result, "Meta result should be undefined: #{meta_result}")

              Owner.cursor(query).toJSON (err, owner) ->
                assert.ok(!err, "No errors: #{err}")
                expected_misses = 2*misses + 1 # two cursor queries plus one direct we did above
                assert.equal(expected_misses, QueryCache.misses, "Same amount of misses after resetting Owner, Expected: #{expected_misses}, Actual: #{QueryCache.misses}")
                assert.equal(0, QueryCache.hits, "No hits after reset")
                done()

    it "Clones data so altering models after retrieval doesn't alter the cached data", (done) ->
      query = {$one: true, $include: ['reverses']}
      Owner.cursor(query).toJSON (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        owner.foo = 'bar'

        QueryCache.get Owner, query, (err, second_json) ->
          assert.ok(!err, "No errors: #{err}")

          assert.ok(!second_json.foo, "Cached object does not have altered property: #{second_json.foo}")
          second_json.bar = 'test2'

          QueryCache.get Owner, query, (err, third_json) ->
            assert.ok(!err, "No errors: #{err}")

            assert.ok(!third_json.foo, "Cached object does not have altered property: #{third_json.foo}")
            assert.ok(!third_json.bar, "Cached object does not have altered property: #{third_json.bar}")
            done()
