util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require '../../../lib/queue'

ModelCache = require('../../../lib/cache/singletons').ModelCache
QueryCache = require('../../../lib/cache/singletons').QueryCache
Fabricator = require '../../fabricator'

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  runTest = (collection_type, done) ->
    model_type = collection_type::model

    queue = new Queue(1)
    queue.defer (callback) -> model_type.resetSchema(callback)
    queue.defer (callback) -> Fabricator.create(model_type, BASE_COUNT, {
      name: Fabricator.uniqueId('model_')
      created_at: Fabricator.date
      updated_at: Fabricator.date
    }, callback)
    queue.await (err) ->
      assert.ok(!err, "No errors: #{err}")
      collection = new collection_type()
      collection.fetch (err, fetched_collection) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(BASE_COUNT, collection.models.length, "collection_type Expected: #{BASE_COUNT}\nActual: #{collection.models.length}")
        assert.equal(BASE_COUNT, fetched_collection.models.length, "Fetched collection_type Expected: #{BASE_COUNT}\nActual: #{fetched_collection.models.length}")
        done()

  ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

  class Model extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/models"
    schema: BASE_SCHEMA
    sync: SYNC(Model)

  describe "Backbone.Collection (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

    before (done) -> return done() unless options.before; options.before([Model], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure model cache
      queue.defer (callback) -> QueryCache.configure({enabled: !!options.query_cache, verbose: false}).reset(callback) # configure query cache
      queue.await done

    it 'fetch models using pre-configured model', (done) ->
      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        model: Model
        sync: SYNC(Collection)
      runTest Collection, done

    it 'fetch models using default model', (done) ->
      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        sync: SYNC(Collection)

      runTest Collection, done

    it 'fetch models using upgraded model', (done) ->
      class SomeModel extends Backbone.Model

      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        model: SomeModel
        sync: SYNC(Collection)

      runTest Collection, done

    it 'fetch models using upgraded model', (done) ->
      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        model: Model
        sync: SYNC(Collection)

      runTest Collection, done
