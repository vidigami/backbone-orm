# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the data.rows for the current run
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

  describe 'Model.page', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    it 'Cursor can chain limit with paging', (done) ->
      ALBUM_NAME = 'Test1'
      Utils.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        limit = 3
        MODEL_TYPE.cursor({$page: true, name: ALBUM_NAME}).limit(limit).toJSON (err, data) ->
          assert.ok(!err, 'no errors')
          assert.ok(data.rows, 'cursor toJSON gives us models')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(data.rows.length, limit, 'found models')
          done()

    it 'Cursor can chain limit and offset with paging', (done) ->
      ALBUM_NAME = 'Test2'
      Utils.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        limit = 2; offset = 1
        MODEL_TYPE.cursor({$page: true, name: ALBUM_NAME}).limit(limit).offset(offset).toJSON (err, data) ->
          assert.ok(!err, 'no errors')
          assert.ok(data.rows, 'cursor toJSON gives us models')
          assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
          assert.equal(data.offset, offset, 'has the correct offset')
          assert.equal(limit, data.rows.length, "Expected: #{limit}, Actual: #{data.rows.length}")
          done()

    it 'Cursor can select fields with paging', (done) ->
      ALBUM_NAME = 'Test3'
      FIELD_NAMES = ['id', 'name']

      Utils.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        MODEL_TYPE.cursor({$page: true, name: ALBUM_NAME}).select(FIELD_NAMES).toJSON (err, data) ->
          assert.ok(!err, 'no errors')
          assert.ok(_.isArray(data.rows), 'cursor toJSON gives us models')
          for json in data.rows
            assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Cursor can select values with paging', (done) ->
      ALBUM_NAME = 'Test4'
      FIELD_NAMES = ['id', 'name']
      Utils.setAllNames MODEL_TYPE, ALBUM_NAME, (err) ->
        assert.ok(!err, 'no errors')

        MODEL_TYPE.cursor({$page: true, name: ALBUM_NAME}).values(FIELD_NAMES).toJSON (err, data) ->
          assert.ok(!err, 'no errors')
          assert.ok(_.isArray(data.rows), 'cursor values is an array')
          for json in data.rows
            assert.ok(_.isArray(json), 'cursor item values is an array')
            assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
          done()
