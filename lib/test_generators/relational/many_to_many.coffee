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
  adapters = Utils.adapters

  describe 'Model.relation', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    it 'Handles a get query for a hasMany and hasMany two sided relation', (done) ->
      Utils.getAt MODEL_TYPE, 0, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        test_model.get 'reverses', (err, models) ->
          assert.ok(!err, 'no errors')
          assert.ok(models, 'found related models')
          related = models[0]

          related.get 'owners', (err, owners) ->
            assert.ok(!err, 'no errors')
            assert.ok(models, 'found related models')

            owner = _.find(owners, (test) -> test_model.get('id') is test.get('id'))
            assert.ok(!!owner, 'found owner')

            if MODEL_TYPE._cache
              assert.deepEqual(JSON.stringify(test_model.toJSON()), JSON.stringify(owner.toJSON()), "\nExpected: #{util.inspect(test_model.toJSON())}\nActual: #{util.inspect(test_model.toJSON())}")
            else
              assert.equal(test_model.get('id'), owner.get('id'), "\nExpected: #{test_model.get('id')}\nActual: #{owner.get('id')}")
            done()
