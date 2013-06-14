# TODO: explain required set up

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

  Utils = require '../../../utils'

  describe 'Model.relation', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    it 'Handles a get query for a hasMany relation', (done) ->
      Utils.getAt MODEL_TYPE, 1, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        test_model.get 'flats', (err, models) ->
          assert.ok(!err, 'no errors')
          assert.ok(models, 'found related models')
          done()

    # TODO: wait for reverse
    # it 'Handles a get query for a hasMany and hasOne two sided relation', (done) ->
    #   Utils.getAt MODEL_TYPE, 1, (err, test_model) ->
    #     assert.ok(!err, 'no errors')
    #     assert.ok(test_model, 'found model')

    #     test_model.get 'many_reverse', (err, models) ->
    #       assert.ok(!err, 'no errors')
    #       assert.ok(models, 'found related models')
    #       related = models[0]

    #       related.get 'many_reverse', (err, original_models) ->
    #         assert.ok(!err, 'no errors')
    #         assert.ok(original_models, 'found related models')

    #         assert.deepEqual(test_model.toJSON(), original_model.toJSON(), "Expected: #{util.inspect(test_model.toJSON())}. Actual: #{util.inspect(original_model.toJSON())}")
    #         done()
