util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
JSONUtils = require '../../../lib/json_utils'

runTests = (options, cache) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 1
  MODELS_JSON = null

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: _.defaults({
      boolean: 'Boolean'
    }, BASE_SCHEMA)
    sync: SYNC(Flat, cache)

  describe "Model.render (cache: #{cache})", ->

    beforeEach (done) ->
      queue = new Queue(1)

      queue.defer (callback) -> Flat.destroy callback

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
        boolean: true
      }, (err, models) ->
        return callback(err) if err
        MODELS_JSON = _.map(models, (test) -> test.toJSON())
        callback()
      )

      queue.await done


    it 'Handles rendering a string', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderJSON test_model


# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
  runTests(options, true)
