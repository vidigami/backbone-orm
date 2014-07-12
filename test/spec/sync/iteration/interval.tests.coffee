assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
_ = BackboneORM._; Backbone = BackboneORM.Backbone
moment = BackboneORM.modules.moment
Queue = BackboneORM.Queue
ModelCache = BackboneORM.CacheSingletons.ModelCache
Utils = BackboneORM.Utils
Fabricator = BackboneORM.Fabricator
try
  streams = require('stream')
  WritableStream = streams.Writable

option_sets = window?.__test__option_sets or require?('../../../option_sets')
parameters = __test__parameters if __test__parameters?
_.each option_sets, exports = (options) ->
  return if options.embed
  options = _.extend({}, options, parameters) if parameters

  describeMaybeSkip = if WritableStream then describe else describe.skip
  describeMaybeSkip "Model.interval #{options.$parameter_tags or ''}#{options.$tags} @slow", ->
    DATABASE_URL = options.database_url or ''
    BASE_SCHEMA = options.schema or {}
    SYNC = options.sync
    BASE_COUNT = 50

    DATE_START = moment.utc('2013-06-09T08:00:00.000Z').toDate()
    DATE_STEP_MS = 1000

    Flat = null
    Counter = null

    before (done) ->
      ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

      class Counter extends WritableStream
        constructor: -> super {objectMode: true}; @count = 0
        _write: (model, encoding, next) -> @count++; next()

      return done() unless options.before; options.before([Flat], done)
    beforeEach (done) ->
      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure model cache

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date(DATE_START, DATE_STEP_MS)
        updated_at: Fabricator.date
      }, callback)

      queue.await done

    it 'callback for all models', (done) ->
      processed_count = 0
      interval_count = 0

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.interval {$interval: {key: 'created_at', range: {$gte: DATE_START}, type: 'milliseconds', length: 2*DATE_STEP_MS}},
          ((query, info, callback) ->
            assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")
            interval_count++
            Flat.each query,
              ((model, callback) ->
                processed_count++
                callback()
              ), callback
          ), callback

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()

    it 'callback for all models - intervalC (CoffeeScript friendly)', (done) ->
      processed_count = 0
      interval_count = 0

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.intervalC {$interval: {key: 'created_at', range: {$gte: DATE_START}, type: 'milliseconds', length: 2*DATE_STEP_MS}}, callback, (query, info, callback) ->
          assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")

          interval_count++
          Flat.eachC query, callback, (model, callback) ->
            processed_count++
            callback()

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()

    it 'callback for all models (model and no range)', (done) ->
      processed_count = 0
      interval_count = 0

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.interval {$interval: {key: 'created_at', type: 'milliseconds', length: 2*DATE_STEP_MS}},
          ((query, info, callback) ->
            assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")
            interval_count++
            Flat.each query,
              ((model, callback) ->
                processed_count++
                callback()
              ), callback
          ), callback

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()

    it 'callback for all models (model and no range) using stream', (done) ->
      processed_count = 0
      interval_count = 0

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.interval {$interval: {key: 'created_at', type: 'milliseconds', length: 2*DATE_STEP_MS}},
          ((query, info, callback) ->
            assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")
            interval_count++

            Flat.stream(query)
              .pipe(counter = new Counter())
              .on('finish', -> processed_count += counter.count; callback())

          ), callback

      queue.await (err) ->
        assert.ifError(err)
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()
