assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, Fabricator} = BackboneORM

try WritableStream = require('stream').Writable; TransformStream = require('stream').Transform

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed or not WritableStream # no streams

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "Stream #{options.$parameter_tags or ''}#{options.$tags}", ->
    Flat = Counter = Filter = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

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
      done = _.once (err) -> assert.ifError(err); callback(err)

      Flat.stream(query)
        .pipe(counter = new Counter())
        .on('finish', -> assert.equal(counter.count, expected); done())
        .on('error', done)

    after (callback) -> Utils.resetSchemas [Flat], callback

    beforeEach (callback) ->
      Utils.resetSchemas [Flat], (err) ->
        return callback(err) if err

        Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, callback

    it 'should support data interface', (callback) ->
      model_count = 0
      done = _.once (err) -> assert.ifError(err); callback(err)

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
