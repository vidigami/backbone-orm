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

  Helpers = require '../../lib/test_helpers'
  adapters = Helpers.adapters

  describe 'Model.cursor', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()


    it 'Handles a count query to json', (done) ->
      MODEL_TYPE.cursor({$count: true}).toJSON (err, count) ->
        assert.ok(!err, 'no errors')
        assert.equal(count, MODELS_JSON.length, 'counted expected number of photos')
        done()

    it 'Cursor makes json', (done) ->
      Helpers.getAt MODEL_TYPE, 0, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        MODEL_TYPE.cursor({id: test_model.get('id')}).toJSON (err, json) ->
          assert.ok(!err, 'no errors')
          assert.ok(json, 'cursor toJSON gives us json')
          assert.ok(json.length, 'json is an array with a length')
          done()

    it 'Cursor makes models', (done) ->
      Helpers.getAt MODEL_TYPE, 0, (err, test_model) ->
        assert.ok(!err, 'no errors')
        assert.ok(test_model, 'found model')

        MODEL_TYPE.cursor({name: test_model.get('id')}).toModels (err, models) ->
          assert.ok(!err, 'no errors')
          assert.ok(models, 'cursor toModels gives us models')
          for model in models
            assert.ok(model instanceof MODEL_TYPE, 'model is the correct type')
          done()

    it 'Cursor can chain limit', (done) ->
      ALBUM_NAME = 'Test1'
      Helpers.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        limit = 3
        MODEL_TYPE.cursor({name: ALBUM_NAME}).limit(limit).toModels (err, models) ->
          assert.ok(!err, 'no errors')
          assert.ok(models, 'cursor toModels gives us models')
          assert.equal(models.length, limit, 'found models')
          done()

    it 'Cursor can chain limit and offset', (done) ->
      ALBUM_NAME = 'Test2'
      Helpers.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        limit = 2; offset = 1
        MODEL_TYPE.cursor({name: ALBUM_NAME}).limit(limit).offset(offset).toModels (err, models) ->
          assert.ok(!err, 'no errors')
          assert.ok(models, 'cursor toModels gives us models')
          assert.equal(limit, models.length, "Expected: #{limit}, Actual: #{models.length}")
          done()

    it 'Cursor can select fields', (done) ->
      ALBUM_NAME = 'Test3'
      FIELD_NAMES = ['id', 'name']

      Helpers.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        MODEL_TYPE.cursor({name: ALBUM_NAME}).select(FIELD_NAMES).toJSON (err, models_json) ->
          assert.ok(!err, 'no errors')
          assert.ok(_.isArray(models_json), 'cursor toJSON gives us models')
          for json in models_json
            assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Cursor can select values', (done) ->
      ALBUM_NAME = 'Test4'
      FIELD_NAMES = ['id', 'name']
      Helpers.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        MODEL_TYPE.cursor({name: ALBUM_NAME}).values(FIELD_NAMES).toJSON (err, values) ->
          assert.ok(!err, 'no errors')
          assert.ok(_.isArray(values), 'cursor values is an array')
          for json in values
            assert.ok(_.isArray(json), 'cursor item values is an array')
            assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Cursor can select the intersection of a whitelist and fields', (done) ->
      ALBUM_NAME = 'Test3'
      WHITE_LIST = ['name']
      FIELD_NAMES = ['id', 'name']

      Helpers.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        MODEL_TYPE.cursor({$white_list: WHITE_LIST}).select(FIELD_NAMES).toJSON (err, models_json) ->
          assert.ok(!err, 'no errors')
          assert.ok(_.isArray(models_json), 'cursor toJSON gives us models')
          for json in models_json
            assert.equal(_.size(json), WHITE_LIST.length, 'gets only the requested values')
            assert.ok(!json['id'], 'does not get a value not in the whitelist')
            assert.equal(json['name'], ALBUM_NAME, 'gets the correct value')
          done()

    it 'Cursor can select the intersection of a whitelist and values', (done) ->
      ALBUM_NAME = 'Test4'
      WHITE_LIST = ['name']
      FIELD_NAMES = ['id', 'name']
      Helpers.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        MODEL_TYPE.cursor({$white_list: WHITE_LIST}).values(FIELD_NAMES).toJSON (err, values) ->
          assert.ok(!err, 'no errors')
          assert.ok(_.isArray(values), 'cursor values is an array')
          for json in values
            assert.ok(_.isArray(json), 'cursor item values is an array')
            assert.equal(json.length, WHITE_LIST.length, 'gets only the requested values')
            assert.equal(json[0], ALBUM_NAME, 'gets the correct value')
          done()
