assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
_ = BackboneORM._; Backbone = BackboneORM.Backbone
Queue = BackboneORM.Queue
ModelCache = BackboneORM.CacheSingletons.ModelCache
Fabricator = BackboneORM.Fabricator
Utils = BackboneORM.Utils

streams = window?.stream or require?('stream')
WritableStream = streams?.Writable
TransformStream = streams?.Transform

option_sets = window?.__test__option_sets or require?('../../../option_sets')
parameters = __test__parameters if __test__parameters?

_.each option_sets, exports = (options) ->
  return if options.embed
  options = _.extend({}, options, parameters) if parameters

  describeMaybeSkip = if WritableStream then describe else describe.skip
  describeMaybeSkip "Stream #{options.$parameter_tags or ''}#{options.$tags}", ->
    DATABASE_URL = options.database_url or ''
    BASE_SCHEMA = options.schema or {}
    SYNC = options.sync
    BASE_COUNT = 5

    Flat = null
    Counter = null
    Filter = null
    pipeCheck = null

    # TODO: document why before is necessary
    before (done) ->
      ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

      class Counter extends WritableStream
        constructor: -> super {objectMode: true}; @count = 0
        _write: (model, encoding, next) -> @count++; next()

      class Filter extends TransformStream
        constructor: (@fn) -> super {objectMode: true}
        _transform: (model, encoding, next) -> @push(model) if @fn(model); next()

      pipeCheck = (query, expected, callback) ->
        done = Utils.debounceCallback (err) -> assert.ifError(err); callback(err)

        Flat.stream(query)
          .pipe(counter = new Counter())
          .on 'finish', -> assert.equal(counter.count, expected); done()
          .on 'error', done

      return done()
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

    it 'should support data interface', (callback) ->
      model_count = 0
      done = Utils.debounceCallback (err) -> assert.ifError(err); callback(err)

      stream = Flat.stream()
      stream.on 'data', (model) -> model_count++
      stream.on 'end', -> assert.equal(model_count, BASE_COUNT); done()
      stream.on 'error', done

    it 'should support pipe interface', (done) ->
      pipeCheck(null, BASE_COUNT, done)

    it 'should support pipe interface with query (name)', (done) ->
      Flat.cursor({$one: true}).toModels (err, model) ->
        assert.ifError(err)
        pipeCheck({name: model.get('name')}, 1, done)

    it 'should support pipe interface with query (limit)', (done) ->
      pipeCheck({$limit: 2}, 2, done)

    it 'should support pipe interface with query (limit + offset)', (done) ->
      pipeCheck({$limit: 2, $offset: BASE_COUNT-1}, 1, done)

    it 'should support pipe interface with transform', (done) ->
      was_called = false
      call_done = (err) ->
        return if was_called; was_called = true
        assert.ifError(err)
        done()

      filter = true
      Flat.stream()
        .pipe(new Filter((model) -> return filter = !filter))
        .pipe(counter = new Counter())
        .on 'finish', ->
          assert.equal(counter.count, Math.floor(BASE_COUNT/2))
          call_done()
        .on 'error', call_done
