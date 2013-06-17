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

  describe 'Model.find', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    it 'Handles a limit query', (done) ->
      MODEL_TYPE.find {$limit: 3}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(models.length, 3, 'found the right number of models')
        done()

    it 'Handles a find id query', (done) ->
      MODEL_TYPE.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        MODEL_TYPE.find test_model.get('id'), (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(model, 'gets a model')
          assert.equal(model.get('id'), test_model.get('id'), 'model has the correct id')
          done()


    it 'Handles another find id query', (done) ->
      MODEL_TYPE.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        MODEL_TYPE.find test_model.get('id'), (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(model, 'gets a model')
          assert.equal(model.get('id'), test_model.get('id'), 'model has the correct id')
          done()


    it 'Handles a find by query id', (done) ->
      MODEL_TYPE.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        MODEL_TYPE.find {id: test_model.get('id')}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, 1, 'finds the model')
          assert.equal(models[0].get('id'), test_model.get('id'), 'model has the correct id')
          done()


    it 'Handles a name find query', (done) ->
      MODEL_TYPE.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        MODEL_TYPE.find {name: test_model.get('name')}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models.length, 'gets models')
          for model in models
            assert.equal(model.get('name'), test_model.get('name'), 'model has the correct name')
          done()
