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

  describe 'hasOne', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    it 'Handles a get query for a hasOne relation', (done) ->
      MODEL_TYPE.find {$one: true}, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        test_model.get 'flat', (err, model) ->
          assert.ok(!err, 'no errors')
          assert.ok(model, 'found related model')
          assert.equal(test_model.get('flat_id'), model.get('id'), "\nExpected: #{test_model.get('flat_id')}\nActual: #{model.get('id')}")
          done()

    it 'Handles a get query for a reversed hasOne relation', (done) ->
      MODEL_TYPE.find {$one: true}, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        test_model.get 'reverse', (err, model) ->
          assert.ok(!err, 'no errors')
          assert.ok(model, 'found related model')
          done()

    it 'Handles a get query for a hasOne and hasOne two sided relation', (done) ->
      MODEL_TYPE.find {$one: true}, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        test_model.get 'reverse', (err, model) ->
          assert.ok(!err, 'no errors')
          assert.ok(model, 'found related model')

          model.get 'owner', (err, owner) ->
            assert.ok(!err, 'no errors')
            assert.ok(owner, 'found original model')

            if MODEL_TYPE._cache
              assert.deepEqual(JSON.stringify(test_model.toJSON()), JSON.stringify(owner.toJSON()), "\nExpected: #{util.inspect(test_model.toJSON())}\nActual: #{util.inspect(owner.toJSON())}")
            else
              assert.equal(test_model.get('id'), owner.get('id'), "\nExpected: #{test_model.get('id')}\nActual: #{owner.get('id')}")
            done()
