util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

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

  describe "Utils.batch (cache: #{cache})", ->

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

    it 'callback for all models (util)', (done) ->
      processed_count = 0

      queue = new Queue(1)
      queue.defer (callback) ->
        Utils.batch Flat, callback, (model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          callback()

      queue.await (err) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(MODELS_JSON.length, processed_count, "\nExpected: #{MODELS_JSON.length}\nActual: #{processed_count}")
        done()

    it 'callback for all models (model)', (done) ->
      processed_count = 0

      queue = new Queue(1)
      queue.defer (callback) ->
        Flat.batch callback, (model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          callback()

      queue.await (err) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(MODELS_JSON.length, processed_count, "\nExpected: #{MODELS_JSON.length}\nActual: #{processed_count}")
        done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
  runTests(options, true)
