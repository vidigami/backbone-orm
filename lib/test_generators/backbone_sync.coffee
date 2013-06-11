# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  MODEL_TYPE = options.model_type
  BEFORE_EACH = options.beforeEach
  MODELS_JSON = null

  util = require 'util'
  assert = require 'assert'
  Queue = require 'queue-async'

  Backbone = require 'backbone'

  Utils = require '../../utils'
  adapters = Utils.adapters

  describe 'BackboneSync', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    describe 'save a model', ->
      it 'assign an id', (done) ->
        bob = new MODEL_TYPE({name: 'Bob'})
        assert.equal(bob.get('name'), 'Bob', 'name before save is Bob')
        assert.ok(!bob.get('id'), 'id before save doesn\'t exist')

        queue = new Queue(1)
        queue.defer (callback) -> bob.save {}, adapters.bbCallback(callback)

        queue.defer (callback) ->
          assert.equal(bob.get('name'), 'Bob', 'name after save is Bob')
          assert.ok(!!bob.get('id'), 'id after save is assigned')
          callback()

        queue.await done

    describe 'fetch model', ->
      it 'fetches data', (done) ->
        Utils.getAt MODEL_TYPE, 1, (err, model) ->
          assert.ok(!err, 'no errors')
          assert.ok(!!model, 'got model')
          new_model = new MODEL_TYPE({id: model.get('id')})

          new_model.fetch adapters.bbCallback (err) ->
            assert.deepEqual(model.attributes, new_model.attributes, "Expected: #{util.inspect(model.attributes)}. Actual: #{util.inspect(new_model.attributes)}")
            done()
