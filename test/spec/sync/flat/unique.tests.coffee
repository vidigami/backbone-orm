assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed and not options.sync.capabilities(options.database_url or '').embed
  return if not options.sync.capabilities(options.database_url or '').unique

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  DATE_INTERVAL_MS = 1000
  START_DATE = new Date()
  END_DATE = new Date(START_DATE.getTime() + (BASE_COUNT - 1) * DATE_INTERVAL_MS)

  describe "Model.unique #{options.$parameter_tags or ''}#{options.$tags} @unique", ->
    Flat = Empty = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: _.defaults({
          boolean: 'Boolean'
        }, BASE_SCHEMA)
        sync: SYNC(Flat)

      class Empty extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/empty"
        schema: _.defaults({
          boolean: 'Boolean'
        }, BASE_SCHEMA)
        sync: SYNC(Empty)

    after (callback) -> Utils.resetSchemas [Flat, Empty], callback

    new_updated_at = null
    beforeEach (callback) ->
      Utils.resetSchemas [Flat, Empty], (err) ->
        return callback(err) if err

        Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date(START_DATE, DATE_INTERVAL_MS)
          updated_at: Fabricator.date
          boolean: true
        }, (err) ->
          Flat.findOne (err, test_model) ->
            assert.ifError(err)
            assert.ok(test_model, 'found model')
            new_updated_at = new Date(test_model.get('updated_at').getTime() + 60*1000)
            test_clone = new Flat({name: test_model.get('name'), updated_at: new_updated_at})
            test_clone.save callback


    it 'Handles a find unique query on one field', (done) ->
      Flat.cursor({$unique: 'name'}).toJSON (err, results) ->
        assert.ifError(err)
        assert.equal(results.length, BASE_COUNT, 'finds no extra results')
        done()

    it 'Handles a find unique query on one field and gives the correct result with sort', (done) ->
      Flat.cursor({$unique: 'name'}).select('created_at', 'updated_at').sort('-updated_at').limit(1).toJSON (err, results) ->
        assert.ifError(err)
        assert.equal(results.length, 1, 'finds no extra results')
        retrieved_clone = results[0]
        assert.equal(retrieved_clone.created_at, null, "loaded model has no created_at")
        assert.equal(retrieved_clone.updated_at.getTime(), new_updated_at.getTime(), "finds the correct model")
        done()

    it 'Handles a find unique query on name with $select', (done) ->
      Flat.cursor({$unique: ['name'], $select: ['id']}).toJSON (err, results) ->
        assert.ifError(err)
        assert.equal(results.length, BASE_COUNT, 'finds no extra results')
        for result in results
          assert.equal(_.keys(result).length, 1, "finds only the $selected field")
          assert.equal(_.keys(result)[0], 'id', "finds only the $selected field")
        done()

    it 'Handles a find unique query on name with select (chaining)', (done) ->
      Flat.cursor().unique('name').select('id').toJSON (err, results) ->
        assert.ifError(err)
        assert.equal(results.length, BASE_COUNT, 'finds no extra results')
        for result in results
          assert.equal(_.keys(result).length, 1, "finds only the $selected field")
          assert.equal(_.keys(result)[0], 'id', "finds only the $selected field")
        done()

    it 'Handles a find unique query on name with $select name', (done) ->
      Flat.cursor({$unique: ['name'], $select: ['name']}).toJSON (err, results) ->
        assert.ifError(err)
        assert.equal(results.length, BASE_COUNT, 'finds no extra results')
        for result in results
          assert.equal(_.keys(result).length, 1, "finds only the $selected field")
          assert.equal(_.keys(result)[0], 'name', "finds only the $selected field")
        done()

    it 'Handles a find unique query on name with $values', (done) ->
      Flat.cursor({$unique: ['name'], $values: ['id']}).toJSON (err, results) ->
        assert.ifError(err)
        assert.equal(results.length, BASE_COUNT, 'finds no extra results')
        for result in results
          assert.ok(!_.isObject(result), "finds only the $selected field")
        done()

    it 'Handles a find unique query on name with $values name', (done) ->
      Flat.cursor({$unique: ['name'], $values: ['name']}).toJSON (err, results) ->
        assert.ifError(err)
        assert.equal(results.length, BASE_COUNT, 'finds no extra results')
        for result in results
          assert.ok(!_.isObject(result), "finds only the $selected field")
        done()

    it 'Handles a find unique query with count', (done) ->
      Flat.count {$unique: 'name'}, (err, result) ->
        assert.ifError(err)
        assert.equal(result, BASE_COUNT, 'finds no extra results')
        done()

    # TODO: test more edge cases
    it 'Handles a find unique query with count on empty collection', (done) ->
      Empty.count {$unique: 'name'}, (err, result) ->
        assert.ifError(err)
        assert.equal(result, 0, 'finds no extra results')
        done()


    describe "Model.unique #{options.$parameter_tags or ''}#{options.$tags} @unique @page", ->

      it 'Cursor can chain limit with paging', (done) ->
        LIMIT = 3
        Flat.cursor({$unique: ['name'], $page: true}).limit(LIMIT).toJSON (err, data) ->
          assert.ifError(err)
          assert.ok(data.rows, 'models received')
          assert.equal(data.total_rows, BASE_COUNT, 'has the correct total_rows')
          assert.equal(data.rows.length, LIMIT, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

      it 'Cursor can chain limit without paging', (done) ->
        LIMIT = 3
        Flat.cursor({$unique: ['name'], $page: false}).limit(LIMIT).toJSON (err, data) ->
          assert.ifError(err)
          assert.equal(data.length, LIMIT, "\nExpected: #{LIMIT}, Actual: #{data.length}")
          done()

      it 'Cursor can chain offset without paging', (done) ->
        OFFSET = 1; COUNT = BASE_COUNT - OFFSET
        Flat.cursor({$unique: ['name'], $page: false}).offset(OFFSET).toJSON (err, data) ->
          assert.ifError(err)
          assert.equal(COUNT, data.length, "\nExpected: #{COUNT}, Actual: #{data.length}")
          done()

      it 'Cursor can chain limit and offset with paging', (done) ->
        LIMIT = 3; OFFSET = 1
        Flat.cursor({$unique: ['name'], $page: true}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
          assert.ifError(err)
          assert.ok(data.rows, 'models received')
          assert.equal(data.total_rows, BASE_COUNT, 'has the correct total_rows')
          assert.equal(data.offset, OFFSET, 'has the correct offset')
          assert.equal(data.rows.length, LIMIT, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

      it 'Cursor can chain limit with paging (no true or false)', (done) ->
        LIMIT = 3; OFFSET = 1
        Flat.cursor({$unique: ['name'], $page: ''}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
          assert.ifError(err)
          assert.ok(data.rows, 'models received')
          assert.equal(data.total_rows, BASE_COUNT, 'has the correct total_rows')
          assert.equal(data.offset, OFFSET, 'has the correct offset')
          assert.equal(data.rows.length, LIMIT, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
          done()

      it 'Cursor can select fields with paging', (done) ->
        FIELD_NAMES = ['id', 'name']
        Flat.cursor({$unique: ['name'], $page: true}).select(FIELD_NAMES).toJSON (err, data) ->
          assert.ifError(err)
          assert.ok(_.isArray(data.rows), 'models received')
          for json in data.rows
            assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
          done()

      it 'Cursor can select values with paging', (done) ->
        FIELD_NAMES = ['id', 'name']
        Flat.cursor({$unique: ['name'], $page: true}).values(FIELD_NAMES).toJSON (err, data) ->
          assert.ifError(err)
          assert.ok(_.isArray(data.rows), 'cursor values is an array')
          for json in data.rows
            assert.ok(_.isArray(json), 'cursor data values is an array')
            assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
          done()


      it 'Ensure paging of one always returns an array of one', (done) ->
        LIMIT = 3; OFFSET = 1
        Flat.cursor({$unique: ['name'], $page: '', $one: true}).limit(LIMIT).offset(OFFSET).toJSON (err, data) ->
          assert.ifError(err)
          assert.ok(data.rows, 'models received')
          assert.equal(data.total_rows, BASE_COUNT, 'has the correct total_rows')
          assert.equal(OFFSET, data.offset, 'has the correct offset')
          assert.equal(1, data.rows.length, "\nExpected: #{LIMIT}, Actual: #{data.rows.length}")
          done()
