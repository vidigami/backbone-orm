# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  MODEL_TYPE = options.model_type
  BEFORE_EACH = options.beforeEach
  MODELS_JSON = null

  assert = require 'assert'
  Queue = require 'queue-async'

  Backbone = require 'backbone'

  Helpers = require '../../lib/test_helpers'
  adapters = Helpers.adapters

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
        Helpers.getAt MODEL_TYPE, 1, (err, model) ->
          assert.ok(!err, 'no errors')
          model_name = model.get('name')
          new_model = new MODEL_TYPE({id: model.get('id')})

          queue = new Queue(1)
          queue.defer (callback) -> new_model.fetch adapters.bbCallback(callback)
          queue.defer (callback) ->
            assert.equal(new_model.get('name'), model_name, 'name after fetch is correct')
            callback()
          queue.await done

    # sync: new BackboneSync({database_config: require('../config/database'), collection: 'bobs', model: MODEL_TYPE, manual_id: true, indices: {id: 1}})
    # TODO: describe 'use a manual id', ->
    #   it 'assign an id', (done) ->

    # TODO: describe 'add an index', ->
