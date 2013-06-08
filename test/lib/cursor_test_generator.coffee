util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Queue = require 'queue-async'

Album = require '../models/album'
AlbumsFabricator = require '../fabricators/albums'
ALBUM_COUNT = 20

Helpers = require '../lib/helpers'
adapters = Helpers.adapters

describe 'Model.cursor', ->

  beforeEach (done) ->
    queue = new Queue(1)
    queue.defer (callback) -> Album.destroy {}, callback
    queue.defer (callback) -> AlbumsFabricator.create ALBUM_COUNT, callback
    queue.await done


  it 'Handles a count query by value', (done) ->
    Album.cursor({$count: true}).value (err, count) ->
      assert.ok(!err, 'no errors')
      assert.equal(count, ALBUM_COUNT, 'counted expected number of photos')
      done()

  it 'Handles a count query to json', (done) ->
    Album.cursor({$count: true}).toJSON (err, count) ->
      assert.ok(!err, 'no errors')
      assert.equal(count, ALBUM_COUNT, 'counted expected number of photos')
      done()

  it 'Cursor makes json', (done) ->
    Helpers.getAt Album, 0, (err, test_model) ->
      assert.ok(!err, 'no errors')
      assert.ok(test_model, 'found model')

      Album.cursor({id: test_model.get('id')}).toJSON (err, json) ->
        assert.ok(!err, 'no errors')
        assert.ok(json, 'cursor toJSON gives us json')
        assert.ok(json.length, 'json is an array with a length')
        done()


  it 'Cursor makes models', (done) ->
    Helpers.getAt Album, 0, (err, test_model) ->
      assert.ok(!err, 'no errors')
      assert.ok(test_model, 'found model')

      Album.cursor({name: test_model.get('id')}).toModels (err, models) ->
        assert.ok(!err, 'no errors')
        assert.ok(models, 'cursor toModels gives us models')
        for model in models
          assert.ok(model instanceof Album, 'model is the correct type')
        done()


  it 'Cursor can chain limit', (done) ->
    ALBUM_NAME = 'Test1'
    Helpers.setAllNames Album, ALBUM_NAME, (err) ->
      assert.ok(!err, 'no errors')

      limit = 3
      Album.cursor({name: ALBUM_NAME}).limit(limit).toModels (err, models) ->
        assert.ok(!err, 'no errors')
        assert.ok(models, 'cursor toModels gives us models')
        assert.equal(models.length, limit, 'found models')
        done()


  it 'Cursor can chain limit and offset', (done) ->
    ALBUM_NAME = 'Test2'
    Helpers.setAllNames Album, ALBUM_NAME, (err) ->
      assert.ok(!err, 'no errors')

      limit = offset = 3
      Album.cursor({name: ALBUM_NAME}).limit(limit).offset(offset).toModels (err, models) ->
        assert.ok(!err, 'no errors')
        assert.ok(models, 'cursor toModels gives us models')
        assert.equal(models.length, limit, 'found models')
        done()


  it 'Cursor can select fields', (done) ->
    ALBUM_NAME = 'Test3'
    FIELD_NAMES = ['id', 'name']

    Helpers.setAllNames Album, ALBUM_NAME, (err) ->
      assert.ok(!err, 'no errors')

      Album.cursor({name: ALBUM_NAME}).select(FIELD_NAMES).toJSON (err, models_json) ->
        assert.ok(!err, 'no errors')
        assert.ok(_.isArray(models_json), 'cursor toJSON gives us models')
        for json in models_json
          assert.equal(_.size(json), FIELD_NAMES.length, 'gets only the requested values')
        done()


  it 'Cursor can select values', (done) ->
    ALBUM_NAME = 'Test4'
    FIELD_NAMES = ['id', 'name']
    Helpers.setAllNames Album, ALBUM_NAME, (err) ->
      assert.ok(!err, 'no errors')

      Album.cursor({name: ALBUM_NAME}).values(FIELD_NAMES).toJSON (err, values) ->
        assert.ok(!err, 'no errors')
        assert.ok(_.isArray(values), 'cursor values is an array')
        for json in values
          assert.ok(_.isArray(json), 'cursor item values is an array')
          assert.equal(json.length, FIELD_NAMES.length, 'gets only the requested values')
        done()
