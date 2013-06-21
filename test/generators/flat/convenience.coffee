util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
adapters = Utils.adapters

runTests = (options, cache) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 1
  MODELS_JSON = null

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat, cache)

  describe "Convenience Methods (cache: #{cache})", ->

    beforeEach (done) ->
      queue = new Queue(1)

      queue.defer (callback) -> Flat.destroy callback

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, (err, models) ->
        return callback(err) if err
        MODELS_JSON = _.map(models, (test) -> test.toJSON())
        callback()
      )

      queue.await done

    describe 'count', ->
      it 'Handles a count query', (done) ->
        Flat.count (err, count) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(count, MODELS_JSON.length, "Expected: #{count}. Actual: #{MODELS_JSON.length}")
          done()

      it 'counts by query', (done) ->
        bob = new Flat({name: 'Bob'})

        queue = new Queue(1)
        queue.defer (callback) -> bob.save {}, adapters.bbCallback(callback)

        queue.defer (callback) ->
          Flat.count {name: 'Bob'}, (err, count) ->
            assert.equal(count, 1, 'found Bob through query')
            callback(err)

        queue.defer (callback) ->
          Flat.count {name: 'Fred'}, (err, count) ->
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
        queue.defer (callback) -> bob.save {}, adapters.bbCallback(callback)
        queue.defer (callback) -> fred.save {}, adapters.bbCallback(callback)

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
          assert.equal(models.length, MODELS_JSON.length, 'counted expected number of albums')
          done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
  runTests(options, true)
