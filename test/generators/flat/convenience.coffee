util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'
moment = require 'moment'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'

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

      queue.defer (callback) -> Flat.resetSchema(callback)

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
        queue.defer (callback) -> bob.save {}, Utils.bbCallback(callback)

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
        queue.defer (callback) -> bob.save {}, Utils.bbCallback(callback)
        queue.defer (callback) -> fred.save {}, Utils.bbCallback(callback)

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
            assert.ok(exists, 'the model exists by name')

            Flat.exists {name: "#{model.get('name')}_thingy"}, (err, exists) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!exists, 'the model does not exist by bad name')

              Flat.exists {created_at: model.get('created_at')}, (err, exists) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(exists, 'the model exists by created_at')

                Flat.exists {created_at: moment('01/01/2001').toDate()}, (err, exists) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(!exists, 'the model does not exist by bad created_at')
                  done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
  runTests(options, true)
