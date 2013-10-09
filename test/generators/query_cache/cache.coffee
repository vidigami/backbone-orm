util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
bbCallback = Utils.bbCallback

QueryCache = require '../../../lib/query_cache'

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  require('../../../lib/cache').hardReset().configure(if options.cache then {max: 100} else null) # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: _.defaults({
      boolean: 'Boolean'
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
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  describe "Query cache (cache: #{options.cache}, embed: #{options.embed})", ->

    before (done) -> return done() unless options.before; options.before([Reverse, Owner], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      QueryCache.configure({enabled: true, verbose: false}).reset() # configure query cache
      require('../../../lib/cache').reset()
      relation = Owner.relation('reverses')
      delete relation.virtual
      MODELS = {}

      queue = new Queue(1)

      # destroy all
      queue.defer (callback) -> Utils.resetSchemas [Reverse, Owner], callback

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
            owner.save {reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]}, bbCallback callback

        save_queue.await callback

      queue.await ->
        QueryCache.reset()  # reset cache
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
      Flat.cursor(query).toJSON (err, flat) ->
        assert.ok(!err, "No errors: #{err}")

        result = QueryCache.getRaw(Flat, query)
        assert.ok(result, "Cache hit: #{result}")
        assert.equal(1, result.model_types.length, "Has one model stored for query, Expected: 1, Actual: #{result.model_types.length}")
        assert.equal(Flat, result.model_types[0], "Has the correct model stored for query, Expected: Flat, Actual: #{result.model_types[0].name}")
        done()

    it 'Can perform the same query twice with a cache hit the second time with a many to many include', (done) ->
      query = {$one: true}
      Owner.cursor(query).include('reverses').toJSON (err, flat) ->
        assert.ok(!err, "No errors: #{err}")

        misses = QueryCache.misses
        assert.equal(0, QueryCache.hits, "No hits after one query")
        Owner.cursor(query).include('reverses').toJSON (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(misses, QueryCache.misses, "No more misses after second query, Expected: #{misses}, Actual: #{QueryCache.misses}")
          assert.notEqual(0, QueryCache.hits, "At least one hit after second query, Expected: >0, Actual: #{QueryCache.hits}")
          done()

    it 'Stores the correct models with the cache result with a many to many include', (done) ->
      query = {$one: true}
      Owner.cursor(query).include('reverses').toJSON (err, flat) ->
        assert.ifError(err, "No errors: #{err}")

        result = QueryCache.getRaw(Owner, query)

        assert.ok(result, "Cache hit: #{result}")
        assert.equal(3, result.model_types.length, "Has three models stored for query, Expected: 3, Actual: #{result.model_types.length}")
        assert.ok(Owner in result.model_types, "Contains an Owner")
        assert.ok(Reverse in result.model_types, "Contains a Reverse")
        JoinTable = Owner.schema().relation('reverses').join_table
        assert.ok(JoinTable in result.model_types, "Contains the JoinTable")
        done()

    it 'Clears the correct models with the cache result with a many to many include', (done) ->
      query = {$one: true}
      Owner.cursor(query).include('reverses').toJSON (err, flat) ->
        assert.ok(!err, "No errors: #{err}")

        misses = QueryCache.misses
        count = QueryCache.count()
        QueryCache.reset(Owner)

        assert.equal(count, QueryCache.clears, "Cleared all the keys after resetting Owner, Expected: #{count}, Actual: #{QueryCache.clears}")
        assert.equal(0, QueryCache.count(), "No keys after reset, Expected: #{0}, Actual: #{QueryCache.count()}")

        Owner.cursor(query).include('reverses').toJSON (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(2*misses, QueryCache.misses, "Same amount of misses after resetting Owner, Expected: #{2*misses}, Actual: #{QueryCache.misses}")
          assert.equal(0, QueryCache.hits, "Still no hits after reset")

        done()
