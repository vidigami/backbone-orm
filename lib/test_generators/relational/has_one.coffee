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

    it 'Handles a get query for a hasOne relation', (done) ->
      Utils.getAt MODEL_TYPE, 1, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        test_model.get 'flat', (err, model) ->
          assert.ok(!err, 'no errors')
          assert.ok(model, 'found related model')

          assert.equal(test_model.get('flat_id'), model.get('id'), "Expected: #{test_model.get('flat_id')}. Actual: #{model.get('id')}")
          done()

    it 'Handles a get query for a reversed hasOne relation', (done) ->
      Utils.getAt MODEL_TYPE, 1, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        test_model.get 'reverse', (err, model) ->
          assert.ok(!err, 'no errors')
          assert.ok(model, 'found related model')
          done()

    it 'Handles a get query for a hasOne and hasOne two sided relation', (done) ->
      Utils.getAt MODEL_TYPE, 1, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        test_model.get 'reverse', (err, model) ->
          assert.ok(!err, 'no errors')
          assert.ok(model, 'found related model')

          model.get 'owner', (err, original_model) ->
            assert.ok(!err, 'no errors')
            assert.ok(original_model, 'found original model')
            assert.equal(test_model.get('id'), original_model.get('id'), 'reverse relation gives the correct model')
            done()
