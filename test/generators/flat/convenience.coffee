util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require '../../../lib/queue'
moment = require 'moment'

ModelCache = require('../../../lib/cache/singletons').ModelCache
QueryCache = require('../../../lib/cache/singletons').QueryCache
Fabricator = require '../../fabricator'
Utils = require '../../../lib/utils'
bbCallback = Utils.bbCallback

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure(if options.cache then {max: 100} else null).hardReset() # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat)

  describe "Convenience Methods (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure model cache
      queue.defer (callback) -> QueryCache.configure({enabled: !!options.query_cache, verbose: false}).reset(callback) # configure query cache

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback)

      queue.await done

    describe 'count', ->
      it 'Handles a count query', (done) ->
        Flat.count (err, count) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(count, BASE_COUNT, "Expected: #{count}. Actual: #{BASE_COUNT}")
          done()

      it 'counts by query', (done) ->
        bob = new Flat({name: 'Bob'})

        queue = new Queue(1)
        queue.defer (callback) -> bob.save {}, bbCallback(callback)

        queue.defer (callback) ->
          Flat.count {name: 'Bob'}, (err, count) ->
            assert.equal(count, 1, 'found Bob through query')
            callback(err)

        queue.defer (callback) ->
          Flat.count {name: 'Fred'}, (err, count) ->
            console.log 'count', count
            assert.equal(count, 0, 'no Fred')
            callback(err)

        queue.defer (callback) ->
          Flat.count {}, (err, count) ->
            assert.ok(count >= 1, 'found Bob through empty query')
            callback(err)

        queue.await done

      it 'counts by query with multiple', (done) ->
        bob = new Flat({name: 'Bob'})
        fred = new Flat({name: 'Fred'})

        queue = new Queue(1)
        queue.defer (callback) -> bob.save {}, bbCallback(callback)
        queue.defer (callback) -> fred.save {}, bbCallback(callback)

        queue.defer (callback) ->
          Flat.count {name: 'Bob'}, (err, count) ->
            assert.equal(count, 1, 'found Bob through query')
            callback(err)

        queue.defer (callback) ->
          Flat.count {name: 'Fred'}, (err, count) ->
            assert.equal(count, 1, 'Fred')
            callback(err)

        queue.defer (callback) ->
          Flat.count {}, (err, count) ->
            assert.ok(count >= 2, 'found Bob and Fred through empty query')
            callback(err)

        queue.defer (callback) ->
          Flat.count (err, count) ->
            assert.ok(count >= 2, 'found Bob and Fred when skipping query')
            callback(err)

        queue.await done

    describe 'all', ->
      it 'Handles an all query', (done) ->
        Flat.all (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, BASE_COUNT, 'counted expected number of albums')
          done()

    describe 'exists', ->
      it 'Handles an exist with no query', (done) ->
        Flat.exists (err, exists) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(exists, 'something exists')
          done()

      it 'Handles an exist query', (done) ->
        Flat.findOne (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(model, 'found a model')

          Flat.exists {name: model.get('name')}, (err, exists) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(exists, "the model exists by name. Expected: #{true}. Actual: #{exists}")

            Flat.exists {name: "#{model.get('name')}_thingy"}, (err, exists) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!exists, "the model does not exist by bad name. Expected: #{false}. Actual: #{exists}")

              Flat.exists {created_at: model.get('created_at')}, (err, exists) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(exists, "the model exists by created_at. Expected: #{true}. Actual: #{exists}")

                Flat.exists {created_at: moment('01/01/2001').toDate()}, (err, exists) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(!exists, "the model does not exist by bad created_at. Expected: #{false}. Actual: #{exists}")
                  done()
