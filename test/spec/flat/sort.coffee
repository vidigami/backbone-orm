assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM or require?('backbone-orm')
_ = BackboneORM._; Backbone = BackboneORM.Backbone
Queue = BackboneORM.Queue
ModelCache = BackboneORM.CacheSingletons.ModelCache
Utils = BackboneORM.Utils
Fabricator = BackboneORM.Fabricator

_.each (require '../../option_sets'), module.exports = (options) ->
  return if options.embed or options.query_cache
  options = _.extend({}, options, test_parameters) if test_parameters?

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: BASE_SCHEMA
    sync: SYNC(Flat)

  describe "Model.sort #{options.$tags}", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    beforeEach (done) ->
      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure model cache

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback)

      queue.await done

    it 'Handles a sort by one field query', (done) ->
      SORT_FIELD = 'name'
      Flat.find {$sort: SORT_FIELD}, (err, models) ->
        assert.ifError(err)
        assert.ok(Utils.isSorted(models, [SORT_FIELD]))
        done()

    it 'Handles a sort by multiple fields query', (done) ->
      SORT_FIELDS = ['name', 'id']
      Flat.find {$sort: SORT_FIELDS}, (err, models) ->
        assert.ifError(err)
        assert.ok(Utils.isSorted(models, SORT_FIELDS))
        done()

    it 'Handles a reverse sort by fields query', (done) ->
      SORT_FIELDS = ['-name', 'id']
      Flat.find {$sort: SORT_FIELDS}, (err, models) ->
        assert.ifError(err)
        assert.ok(Utils.isSorted(models, SORT_FIELDS))
        done()

    it 'should sort by id', (done) ->
      Flat.cursor().sort('id').toModels (err, models) ->
        assert.ifError(err)

        ids = (model.id for model in models)
        sorted_ids = _.clone(ids).sort()
        assert.deepEqual(ids, sorted_ids, "Models were returned in sorted order")
        done()