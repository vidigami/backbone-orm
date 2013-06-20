util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../utils'
adapters = Utils.adapters

runTests = (options, cache) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  MODELS_JSON = null

  class Flat extends Backbone.Model
    url: "#{DATABASE_URL}/flats"
    sync: SYNC(Flat, cache)

  describe "Model.cursor (cache: #{cache})", ->

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

    it 'Handles a count query to json', (done) ->
      Flat.cursor({$count: true}).toJSON (err, count) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(MODELS_JSON.length, count, "\nExpected: #{MODELS_JSON.length}\nActual: #{count}")
        done()

    it 'Cursor makes json', (done) ->
      Flat.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        Flat.cursor({id: test_model.get('id')}).toJSON (err, json) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(json, 'cursor toJSON gives us json')
          assert.ok(json.length, 'json is an array with a length')
          done()

    it 'Cursor makes models', (done) ->
      Flat.find {$one: true}, (err, test_model) ->
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
      Utils.setAllNames Flat, ALBUM_NAME, (err) ->
        assert.ok(!err, "No errors: #{err}")

        limit = 3
        Flat.cursor({name: ALBUM_NAME}).limit(limit).toModels (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models, 'cursor toModels gives us models')
          assert.equal(models.length, limit, 'found models')
          done()

    it 'Cursor can chain limit and offset', (done) ->
      ALBUM_NAME = 'Test2'
      Utils.setAllNames Flat, ALBUM_NAME, (err) ->
        assert.ok(!err, "No errors: #{err}")

        limit = 2; offset = 1
        Flat.cursor({name: ALBUM_NAME}).limit(limit).offset(offset).toModels (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models, 'cursor toModels gives us models')
          assert.equal(limit, models.length, "\nExpected: #{limit}, Actual: #{models.length}")
          done()

    it 'Cursor can select fields', (done) ->
      ALBUM_NAME = 'Test3'
      FIELD_NAMES = ['id', 'name']

      Utils.setAllNames Flat, ALBUM_NAME, (err) ->
        assert.ok(!err, "No errors: #{err}")

        Flat.cursor({name: ALBUM_NAME}).select(FIELD_NAMES).toJSON (err, models_json) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(_.isArray(models_json), 'cursor toJSON gives us models')
          for json in models_json
            assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Cursor can select values', (done) ->
      ALBUM_NAME = 'Test4'
      FIELD_NAMES = ['id', 'name']
      Utils.setAllNames Flat, ALBUM_NAME, (err) ->
        assert.ok(!err, "No errors: #{err}")

        Flat.cursor({name: ALBUM_NAME}).values(FIELD_NAMES).toJSON (err, values) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(_.isArray(values), 'cursor values is an array')
          for json in values
            assert.ok(_.isArray(json), 'cursor item values is an array')
            assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
          done()

    it 'Cursor can select the intersection of a whitelist and fields', (done) ->
      ALBUM_NAME = 'Test3'
      WHITE_LIST = ['name']
      FIELD_NAMES = ['id', 'name']

      Utils.setAllNames Flat, ALBUM_NAME, (err) ->
        assert.ok(!err, "No errors: #{err}")

        Flat.cursor({$white_list: WHITE_LIST}).select(FIELD_NAMES).toJSON (err, models_json) ->
          assert.ok(!err, "No errors: #{err}")
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
      Utils.setAllNames Flat, ALBUM_NAME, (err) ->
        assert.ok(!err, "No errors: #{err}")

        Flat.cursor({$white_list: WHITE_LIST}).values(FIELD_NAMES).toJSON (err, values) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(_.isArray(values), 'cursor values is an array')
          for json in values
            assert.ok(_.isArray(json), 'cursor item values is an array')
            assert.equal(json.length, WHITE_LIST.length, 'gets only the requested values')
            assert.equal(json[0], ALBUM_NAME, 'gets the correct value')
          done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
  runTests(options, true)