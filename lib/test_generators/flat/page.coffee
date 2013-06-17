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

  Utils = require '../../../utils'
  adapters = Utils.adapters

  describe 'Model.page', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    it 'Cursor can chain limit with paging', (done) ->
      LIMIT = 3
      MODEL_TYPE.cursor({$page: true}).limit(LIMIT).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
        assert.equal(LIMIT, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()

    it 'Cursor can chain limit without paging', (done) ->
      LIMIT = 3
      MODEL_TYPE.cursor({$page: false}).limit(LIMIT).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(LIMIT, data.length, "\nExpected: #{LIMIT}, Actual: #{data.length}")
        done()

    it 'Cursor can chain limit and offset with paging', (done) ->
      LIMIT = 3; OFFSET = 1
      MODEL_TYPE.cursor({$page: true}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
        assert.equal(OFFSET, data.offset, 'has the correct offset')
        assert.equal(LIMIT, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()

    it 'Cursor can chain limit with paging (no true or false)', (done) ->
      LIMIT = 3; OFFSET = 1
      MODEL_TYPE.cursor({$page: ''}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
        assert.equal(OFFSET, data.offset, 'has the correct offset')
        assert.equal(LIMIT, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()

    it 'Cursor can select fields with paging', (done) ->
      FIELD_NAMES = ['id', 'name']
      MODEL_TYPE.cursor({$page: true}).select(FIELD_NAMES).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(_.isArray(data.rows), 'models received')
        for json in data.rows
          assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
        done()

    it 'Cursor can select values with paging', (done) ->
      FIELD_NAMES = ['id', 'name']
      MODEL_TYPE.cursor({$page: true}).values(FIELD_NAMES).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(_.isArray(data.rows), 'cursor values is an array')
        for json in data.rows
          assert.ok(_.isArray(json), 'cursor item values is an array')
          assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
        done()

    it 'Ensure the correct value is returned', (done) ->
      MODEL_TYPE.find {$one: true}, (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!model, 'model')
        MODEL_TYPE.cursor({$page: true, name: model.get('name')}).toJSON (err, data) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(data.total_rows, 1, 'has the correct total_rows')
          assert.equal(data.rows.length, 1, 'has the correct row.length')
          assert.deepEqual(expected = JSON.stringify(model.toJSON()), actual = JSON.stringify(data.rows[0]), "\nExpected: #{util.inspect(expected)}\nActual: #{util.inspect(actual)}")
          done()
