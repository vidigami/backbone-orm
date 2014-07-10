assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM or require?('backbone-orm')
_ = BackboneORM._; Backbone = BackboneORM.Backbone
moment = BackboneORM.modules.moment
Queue = BackboneORM.Queue
ModelCache = BackboneORM.CacheSingletons.ModelCache
Fabricator = BackboneORM.Fabricator
_.each (require '../../option_sets'), module.exports = (options) ->
  return if options.embed or options.query_cache

  # load the globally defined test parameters (used by backbone-mongo, backbone-http, etc.)
  # (either load it in the browser with a script tag, use karma's options to load it in the browser, or use mocha --require ./test_parameters ...)
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

  # use tags to grep out certain option sets https://github.com/visionmedia/mocha/wiki/Tagging
  describe "Model.each #{options.$tags}", ->

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

    it 'callback for all models', (done) ->
      processed_count = 0

      queue = new Queue(1)
      queue.defer (callback) ->
        Flat.eachC callback, (model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          callback()

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT, processed_count, "\nExpected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()

    it 'callback for queried models', (done) ->
      processed_count = 0

      queue = new Queue(1)
      queue.defer (callback) ->
        Flat.eachC callback, (model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          callback()

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT, processed_count, "\nExpected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()
