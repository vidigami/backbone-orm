# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  MODEL_TYPE = options.model_type
  BEFORE_EACH = options.beforeEach
  MODELS_JSON = null

  util = require 'util'
  assert = require 'assert'
  _ = require 'underscore'
  Queue = require 'queue-async'

  Utils = require '../../utils'
  adapters = Utils.adapters

  describe 'Model.relation', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    it 'Handles a get query for a relation', (done) ->
      Utils.getAt MODEL_TYPE, 1, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        queue = new Queue(1)
        queue.defer (callback) -> test_model.get 'photos', adapters.bbCallback(callback)

        queue.defer (callback) ->
          assert.ok(!err, 'no errors')
          assert.equal(MODELS_JSON.length, count, "Expected: #{MODELS_JSON.length}. Actual: #{count}")
          callback()

        queue.await done