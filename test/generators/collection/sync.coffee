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

  class Model extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/models"
    @schema: BASE_SCHEMA
    sync: SYNC(Model)

  describe "Backbone.Collection (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

    before (done) -> return done() unless options.before; options.before([Model], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      require('../../../lib/query_cache').reset()  # reset cache
      require('../../../lib/cache').reset()
      queue = new Queue(1)

      queue.defer (callback) -> Model.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Model, BASE_COUNT, {
        name: Fabricator.uniqueId('model_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback)

      queue.await done

    it 'fetch models using pre-configured model', (done) ->
      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        model: Model
        sync: SYNC(Collection)

      collection = new Collection()
      collection.fetch bbCallback (err, fetched_collection) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(BASE_COUNT, collection.models.length, "Collection Expected: #{BASE_COUNT}\nActual: #{collection.models.length}")
        assert.equal(BASE_COUNT, fetched_collection.models.length, "Fetched Collection Expected: #{BASE_COUNT}\nActual: #{fetched_collection.models.length}")
        done()

    it 'fetch models using default model', (done) ->
      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        sync: SYNC(Collection)

      runTest = (err) ->
        return done(err) if err

        collection = new Collection()
        collection.fetch bbCallback (err, fetched_collection) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(BASE_COUNT, collection.models.length, "Collection Expected: #{BASE_COUNT}\nActual: #{collection.models.length}")
          assert.equal(BASE_COUNT, fetched_collection.models.length, "Fetched Collection Expected: #{BASE_COUNT}\nActual: #{fetched_collection.models.length}")
          done()

      if options.before
        options.before([Collection::model], runTest)
      else
        runTest()

    it 'fetch models using upgraded model', (done) ->
      class SomeModel extends Backbone.Model

      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        model: SomeModel
        sync: SYNC(Collection)

      runTest = (err) ->
        return done(err) if err

        collection = new Collection()
        collection.fetch bbCallback (err, fetched_collection) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(BASE_COUNT, collection.models.length, "Collection Expected: #{BASE_COUNT}\nActual: #{collection.models.length}")
          assert.equal(BASE_COUNT, fetched_collection.models.length, "Fetched Collection Expected: #{BASE_COUNT}\nActual: #{fetched_collection.models.length}")
          done()

      if options.before
        options.before([Collection::model], runTest)
      else
        runTest()

    it 'fetch models using upgraded model', (done) ->
      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        model: Model
        sync: SYNC(Collection)

      runTest = (err) ->
        return done(err) if err

        Model.all (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models.length, 'Found models')

          collection = new Collection(model.toJSON() for model in models)
          for model in models
            found_model = collection.get(model.id)
            if options.cache
              assert.equal(model, found_model, "Model found in cache")
            else
              assert.notEqual(model, found_model, "Model not found in cache")
          done()

      if options.before
        options.before([Collection::model], runTest)
      else
        runTest()
