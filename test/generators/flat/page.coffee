util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
adapters = Utils.adapters

runTests = (options, cache) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  MODELS_JSON = null

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat, cache)

  describe "Model.page (cache: #{cache})", ->

    beforeEach (done) ->
      queue = new Queue(1)

      queue.defer (callback) -> Flat.destroy callback

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, (err, models) ->
        return callback(err) if err
        MODELS_JSON = _.map(models, (test) -> test.toJSON())
        callback()
      )

      queue.await done

    it 'Cursor can chain limit with paging', (done) ->
      LIMIT = 3
      Flat.cursor({$page: true}).limit(LIMIT).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
        assert.equal(LIMIT, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()

    it 'Cursor can chain limit without paging', (done) ->
      LIMIT = 3
      Flat.cursor({$page: false}).limit(LIMIT).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(LIMIT, data.length, "\nExpected: #{LIMIT}, Actual: #{data.length}")
        done()

    it 'Cursor can chain limit and offset with paging', (done) ->
      LIMIT = 3; OFFSET = 1
      Flat.cursor({$page: true}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
        assert.equal(OFFSET, data.offset, 'has the correct offset')
        assert.equal(LIMIT, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()

    it 'Cursor can chain limit with paging (no true or false)', (done) ->
      LIMIT = 3; OFFSET = 1
      Flat.cursor({$page: ''}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, MODELS_JSON.length, 'has the correct total_rows')
        assert.equal(OFFSET, data.offset, 'has the correct offset')
        assert.equal(LIMIT, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()

    it 'Cursor can select fields with paging', (done) ->
      FIELD_NAMES = ['id', 'name']
      Flat.cursor({$page: true}).select(FIELD_NAMES).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(_.isArray(data.rows), 'models received')
        for json in data.rows
          assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
        done()

    it 'Cursor can select values with paging', (done) ->
      FIELD_NAMES = ['id', 'name']
      Flat.cursor({$page: true}).values(FIELD_NAMES).toJSON (err, data) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(_.isArray(data.rows), 'cursor values is an array')
        for json in data.rows
          assert.ok(_.isArray(json), 'cursor item values is an array')
          assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
        done()

    it 'Ensure the correct value is returned', (done) ->
      Flat.find {$one: true}, (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!model, 'model')
        Flat.cursor({$page: true, name: model.get('name')}).toJSON (err, data) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(data.total_rows, 1, 'has the correct total_rows')
          assert.equal(data.rows.length, 1, 'has the correct row.length')
          assert.deepEqual(expected = model.toJSON().id, actual = data.rows[0].id, "\nExpected: #{util.inspect(expected)}\nActual: #{util.inspect(actual)}")
          done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
  runTests(options, true)
