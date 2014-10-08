assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "Model.page #{options.$parameter_tags or ''}#{options.$tags} @page", ->
    Flat = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

    after (callback) -> Utils.resetSchemas [Flat], callback

    beforeEach (callback) ->
      Utils.resetSchemas [Flat], (err) ->
        return callback(err) if err

        Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, callback

    it 'Cursor can chain limit with paging', (done) ->
      LIMIT = 3
      Flat.cursor({$page: true}).limit(LIMIT).toJSON (err, data) ->
        assert.ifError(err)
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, BASE_COUNT, 'has the correct total_rows')
        assert.equal(data.rows.length, LIMIT, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()

    it 'Cursor can chain limit without paging', (done) ->
      LIMIT = 3
      Flat.cursor({$page: false}).limit(LIMIT).toJSON (err, data) ->
        assert.ifError(err)
        assert.equal(LIMIT, data.length, "\nExpected: #{LIMIT}, Actual: #{data.length}")
        done()

    it 'Cursor can chain offset without paging', (done) ->
      OFFSET = 1; COUNT = BASE_COUNT - OFFSET
      Flat.cursor({$page: false}).offset(OFFSET).toJSON (err, data) ->
        assert.ifError(err)
        assert.equal(COUNT, data.length, "\nExpected: #{COUNT}, Actual: #{data.length}")
        done()

    it 'Cursor can chain limit and offset with paging', (done) ->
      LIMIT = 3; OFFSET = 1
      Flat.cursor({$page: true}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
        assert.ifError(err)
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, BASE_COUNT, 'has the correct total_rows')
        assert.equal(OFFSET, data.offset, 'has the correct offset')
        assert.equal(LIMIT, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()

    it 'Cursor can chain limit with paging (no true or false)', (done) ->
      LIMIT = 3; OFFSET = 1
      Flat.cursor({$page: ''}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
        assert.ifError(err)
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, BASE_COUNT, 'has the correct total_rows')
        assert.equal(OFFSET, data.offset, 'has the correct offset')
        assert.equal(LIMIT, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()

    it 'Cursor can select fields with paging', (done) ->
      FIELD_NAMES = ['id', 'name']
      Flat.cursor({$page: true}).select(FIELD_NAMES).toJSON (err, data) ->
        assert.ifError(err)
        assert.ok(_.isArray(data.rows), 'models received')
        for json in data.rows
          assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
        done()

    it 'Cursor can select values with paging', (done) ->
      FIELD_NAMES = ['id', 'name']
      Flat.cursor({$page: true}).values(FIELD_NAMES).toJSON (err, data) ->
        assert.ifError(err)
        assert.ok(_.isArray(data.rows), 'cursor values is an array')
        for json in data.rows
          assert.ok(_.isArray(json), 'cursor data values is an array')
          assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
        done()

    it 'Ensure the correct value is returned', (done) ->
      Flat.findOne (err, model) ->
        assert.ifError(err)
        assert.ok(!!model, 'model')
        Flat.cursor({$page: true, name: model.get('name')}).toJSON (err, data) ->
          assert.ifError(err)
          assert.equal(data.total_rows, 1, 'has the correct total_rows')
          assert.equal(data.rows.length, 1, 'has the correct row.length')
          assert.deepEqual(expected = model.toJSON().id, actual = data.rows[0].id, "\nExpected: #{JSONUtils.stringify(expected)}\nActual: #{JSONUtils.stringify(actual)}")
          done()

    it 'Ensure paging of one always returns an array of one', (done) ->
      LIMIT = 3; OFFSET = 1
      Flat.cursor({$page: '', $one: true}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
        assert.ifError(err)
        assert.ok(data.rows, 'models received')
        assert.equal(data.total_rows, BASE_COUNT, 'has the correct total_rows')
        assert.equal(OFFSET, data.offset, 'has the correct offset')
        assert.equal(1, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
        done()
