util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
bbCallback = Utils.bbCallback

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  require('../../../lib/query_cache').configure({enabled: options.query_cache}).reset() # configure query cache
  require('../../../lib/cache').hardReset().configure(if options.cache then {max: 100} else null) # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: _.defaults({
      boolean: 'Boolean'
    }, BASE_SCHEMA)
    sync: SYNC(Flat)

  describe "Model.cursor (cache: #{options.cache})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      require('../../../lib/query_cache').reset()  # reset cache
      require('../../../lib/cache').reset()
      queue = new Queue(1)

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
        boolean: true
      }, callback)

      queue.await done

    it 'Handles a count query to json', (done) ->
      Flat.cursor({$count: true}).toJSON (err, count) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(BASE_COUNT, count, "\nExpected: #{BASE_COUNT}\nActual: #{count}")
        done()

    it 'Cursor makes json', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        Flat.cursor({id: test_model.id}).toJSON (err, json) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(json, 'cursor toJSON gives us json')
          assert.ok(json.length, 'json is an array with a length')
          done()

    it 'Cursor makes models', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        Flat.cursor({name: test_model.get('name')}).toModels (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models, 'cursor toModels gives us models')
          for model in models
            assert.ok(model instanceof Flat, 'model is the correct type')
          done()

    it 'Cursor can chain limit', (done) ->
      ALBUM_NAME = 'Test1'

      runTest = (err) ->
        assert.ok(!err, "No errors: #{err}")

        limit = 3
        Flat.cursor({name: ALBUM_NAME}).limit(limit).toModels (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models, 'cursor toModels gives us models')
          assert.equal(models.length, limit, 'found models')
          done()

      Flat.batch runTest, (model, callback) -> model.save {name: ALBUM_NAME}, bbCallback callback

    it 'Cursor can chain limit and offset', (done) ->
      ALBUM_NAME = 'Test2'

      runTest = (err) ->
        assert.ok(!err, "No errors: #{err}")

        limit = 2; offset = 1
        Flat.cursor({name: ALBUM_NAME}).limit(limit).offset(offset).toModels (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models, 'cursor toModels gives us models')
          assert.equal(limit, models.length, "\nExpected: #{limit}, Actual: #{models.length}")
          done()

      Flat.batch runTest, (model, callback) -> model.save {name: ALBUM_NAME}, bbCallback callback

    it 'Cursor can select fields', (done) ->
      ALBUM_NAME = 'Test3'
      FIELD_NAMES = ['id', 'name']

      runTest = (err) ->
        assert.ok(!err, "No errors: #{err}")

        Flat.cursor({name: ALBUM_NAME}).select(FIELD_NAMES).toJSON (err, models_json) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(_.isArray(models_json), 'cursor toJSON gives us models')
          for json in models_json
            assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
          done()

      Flat.batch runTest, (model, callback) -> model.save {name: ALBUM_NAME}, bbCallback callback

    it 'Cursor can select values', (done) ->
      ALBUM_NAME = 'Test4'
      FIELD_NAMES = ['id', 'name']

      runTest = (err) ->
        assert.ok(!err, "No errors: #{err}")

        Flat.cursor({name: ALBUM_NAME}).values(FIELD_NAMES).toJSON (err, values) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(_.isArray(values), 'cursor values is an array')
          for json in values
            assert.ok(_.isArray(json), 'cursor data values is an array')
            assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
          done()

      Flat.batch runTest, (model, callback) -> model.save {name: ALBUM_NAME}, bbCallback callback

    it 'Cursor can select the intersection of a whitelist and fields', (done) ->
      ALBUM_NAME = 'Test3'
      WHITE_LIST = ['name']
      FIELD_NAMES = ['id', 'name']

      runTest = (err) ->
        assert.ok(!err, "No errors: #{err}")

        Flat.cursor({$white_list: WHITE_LIST}).select(FIELD_NAMES).toJSON (err, models_json) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(_.isArray(models_json), 'cursor toJSON gives us models')
          for json in models_json
            assert.equal(_.size(json), WHITE_LIST.length, 'gets only the requested values')
            assert.ok(!json['id'], 'does not get a value not in the whitelist')
            assert.equal(json['name'], ALBUM_NAME, 'gets the correct value')
          done()

      Flat.batch runTest, (model, callback) -> model.save {name: ALBUM_NAME}, bbCallback callback

    it 'Cursor can select the intersection of a whitelist and values', (done) ->
      ALBUM_NAME = 'Test4'
      WHITE_LIST = ['name']
      FIELD_NAMES = ['id', 'name']

      runTest = (err) ->
        assert.ok(!err, "No errors: #{err}")

        Flat.cursor({$white_list: WHITE_LIST}).values(FIELD_NAMES).toJSON (err, values) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(_.isArray(values), 'cursor values is an array')
          for json in values
            assert.ok(_.isArray(json), 'cursor data values is an array')
            assert.equal(json.length, WHITE_LIST.length, 'gets only the requested values')
            assert.equal(json[0], ALBUM_NAME, 'gets the correct value')
          done()

      Flat.batch runTest, (model, callback) -> model.save {name: ALBUM_NAME}, bbCallback callback

    it 'Cursor can perform an $in query', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        $in = ['random_string', 'some_9', test_model.get('name')]

        Flat.cursor({name: {$in: $in}}).toModels (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models, 'cursor toModels gives us models')
          assert.ok(models.length, 'cursor toModels gives us one model')
          for model in models
            assert.equal(test_model.get('name'), model.get('name'), "Names match:\nExpected: #{test_model.get('name')}, Actual: #{model.get('name')}")
          done()

    it 'Cursor can retrieve a boolean as a boolean', (done) ->
      Flat.cursor({$one: true}).toJSON (err, json) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(json, 'found json')
        assert.equal(typeof json.boolean, 'boolean', "Is a boolean:\nExpected: 'boolean', Actual: #{typeof json.boolean}")
        assert.deepEqual(json.boolean, true, "Bool matches:\nExpected: #{true}, Actual: #{json.boolean}")
        done()
