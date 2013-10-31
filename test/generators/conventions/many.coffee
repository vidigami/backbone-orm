util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require '../../../lib/queue'

ModelCache = require('../../../lib/cache/singletons').ModelCache
QueryCache = require('../../../lib/cache/singletons').QueryCache
Fabricator = require '../../fabricator'
Utils = require '../../../lib/utils'

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    schema: _.defaults({
      owners: -> ['HasMany', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Reverse)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    schema: _.defaults({
      reverses: -> ['has_many', Reverse]
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  describe "Many (cache: #{options.cache}, query_cache: #{options.query_cache}, embed: #{options.embed})", ->

    before (done) -> return done() unless options.before; options.before([Reverse, Owner], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      MODELS = {}

      queue = new Queue(1)

      # reset query cache
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure model cache
      queue.defer (callback) -> QueryCache.configure({enabled: !!options.query_cache, verbose: false}).reset(callback) # configure query cache

      # destroy all
      queue.defer (callback) -> Utils.resetSchemas [Reverse, Owner], callback

      # create all
      queue.defer (callback) ->
        create_queue = new Queue()

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
            owner.save {reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]}, callback

        save_queue.await callback

      queue.await done

    it 'Handles a get query for a hasMany and hasMany two sided relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        test_model.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses.length, 'found related reverses')
          if test_model.relationIsEmbedded('reverses')
            assert.deepEqual(test_model.toJSON().reverses[0], reverses[0].toJSON(), "Serialized embedded. Expected: #{test_model.toJSON().reverses}. Actual: #{reverses[0].toJSON()}")
          else
            assert.deepEqual(test_model.get('reverse_ids')[0], reverses[0].id, "Serialized id only. Expected: #{test_model.get('reverse_ids')[0]}. Actual: #{reverses[0].id}")
          reverse = reverses[0]

          reverse.get 'owners', (err, owners) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owners.length, 'found related models')

            owner = _.find(owners, (test) -> test_model.id is test.id)
            owner_index = _.indexOf(owners, owner)
            if reverse.relationIsEmbedded('owners')
              assert.deepEqual(reverse.toJSON().owner_ids[owner_index], owner.id, "Serialized embedded. Expected: #{reverse.toJSON().owner_ids[owner_index]}. Actual: #{owner.id}")
            else
              assert.deepEqual(reverse.get('owner_ids')[owner_index], owner.id, "Serialized id only. Expected: #{reverse.get('owner_ids')[owner_index]}. Actual: #{owner.id}")
            assert.ok(!!owner, 'found owner')

            if Owner.cache
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "\nExpected: #{util.inspect(test_model.toJSON())}\nActual: #{util.inspect(test_model.toJSON())}")
            else
              assert.equal(test_model.id, owner.id, "\nExpected: #{test_model.id}\nActual: #{owner.id}")
            done()

