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

  describe "Backbone.Collection #{options.$parameter_tags or ''}#{options.$tags}", ->
    runTest = (collection_type, done) ->
      model_type = collection_type::model

      queue = new Queue(1)
      queue.defer (callback) -> model_type.resetSchema(callback)
      queue.defer (callback) -> Fabricator.create model_type, BASE_COUNT, {
        name: Fabricator.uniqueId('model_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback

      queue.defer (callback) ->
        collection = new collection_type()
        collection.fetch (err, fetched_collection) ->
          assert.ifError(err)
          assert.equal(BASE_COUNT, collection.models.length, "collection_type Expected: #{BASE_COUNT}\nActual: #{collection.models.length}")
          assert.equal(BASE_COUNT, fetched_collection.models.length, "Fetched collection_type Expected: #{BASE_COUNT}\nActual: #{fetched_collection.models.length}")
          callback()

      queue.defer (callback) ->
        Utils.resetSchemas [model_type], callback

      queue.await (err) ->
        assert.ifError(err)
        done()

    it 'fetch models using pre-configured model', (done) ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Model extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/models"
        schema: BASE_SCHEMA
        sync: SYNC(Model)

      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        model: Model
        schema: BASE_SCHEMA
        sync: SYNC(Collection)

      runTest Collection, done

    it 'fetch models using default model', (done) ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        schema: BASE_SCHEMA
        sync: SYNC(Collection)

      runTest Collection, done

    it 'fetch models using upgraded model', (done) ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class SomeModel extends Backbone.Model

      class Collection extends Backbone.Collection
        url: "#{DATABASE_URL}/models"
        model: SomeModel
        schema: BASE_SCHEMA
        sync: SYNC(Collection)

      runTest Collection, done
