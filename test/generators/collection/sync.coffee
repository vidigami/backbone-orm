util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
bbCallback = Utils.bbCallback

runTests = (options, cache, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  require('../../../lib/cache').configure(if cache then {max: 100} else null) # configure caching

  class Model extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/models"
    @schema: BASE_SCHEMA
    sync: SYNC(Model)

  describe "Utils.batch (cache: #{cache})", ->

    before (done) -> return done() unless options.before; options.before([Model], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      require('../../../lib/cache').reset() # reset cache
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

      collection = new Collection()
      collection.fetch bbCallback (err, fetched_collection) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(BASE_COUNT, collection.models.length, "Collection Expected: #{BASE_COUNT}\nActual: #{collection.models.length}")
        assert.equal(BASE_COUNT, fetched_collection.models.length, "Fetched Collection Expected: #{BASE_COUNT}\nActual: #{fetched_collection.models.length}")
        done()

    it 'fetch models using upgraded model', (done) ->
      class SomeModel extends Backbone.Model

      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        model: SomeModel
        sync: SYNC(Collection)

      collection = new Collection()
      collection.fetch bbCallback (err, fetched_collection) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(BASE_COUNT, collection.models.length, "Collection Expected: #{BASE_COUNT}\nActual: #{collection.models.length}")
        assert.equal(BASE_COUNT, fetched_collection.models.length, "Fetched Collection Expected: #{BASE_COUNT}\nActual: #{fetched_collection.models.length}")
        done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> runTests(options, false, callback)
  queue.defer (callback) -> runTests(options, true, callback)
  queue.await callback
