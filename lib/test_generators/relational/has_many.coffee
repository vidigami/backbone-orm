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

    # it 'Handles a get query for a hasMany relation', (done) ->
    #   Utils.getAt MODEL_TYPE, 1, (err, test_model) ->
    #     assert.ok(!err, 'no errors')
    #     assert.ok(test_model, 'found model')

    #     test_model.get 'many', (err, models) ->
    #       assert.ok(!err, 'no errors')
    #       assert.ok(models, 'found related models')
    #       done()

    it 'Handles a get query for a hasMany and hasOne two sided relation', (done) ->
      Utils.getAt MODEL_TYPE, 1, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        test_model.get 'many_reverse', (err, models) ->
          assert.ok(!err, 'no errors')
          assert.ok(models, 'found related models')
          related = models[0]

          console.log "related: #{related.get}"

          related.get 'many_reverse', (err, original_model) ->
            console.log "original_model: #{util.inspect(original_model)}"

            assert.equal(test_model, original_model, 'reverse relation gives the correct model')
            done()
