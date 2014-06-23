util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'

Fabricator = require '../../fabricator'

try BackboneORM = require 'backbone-orm' catch err then BackboneORM = require('../../../backbone-orm')
Queue = BackboneORM.Queue
ModelCache = BackboneORM.CacheSingletons.ModelCache

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: BASE_SCHEMA
    sync: SYNC(Flat)

  class Counter extends require('stream').Writable
    constructor: -> super {objectMode: true}; @count = 0
    _write: (model, encoding, next) -> @count++; next()

  class Filter extends require('stream').Transform
    constructor: (@fn) -> super {objectMode: true}
    _transform: (model, encoding, next) -> @push(model) if @fn(model); next()

  pipeCheck = (query, expected, done) ->
    was_called = false
    call_done = (err) ->
      return if was_called; was_called = true
      assert.ok(!err, "No errors: #{err}")
      done()

    Flat.stream(query)
      .pipe(counter = new Counter())
      .on 'finish', ->
        assert.equal(counter.count, expected)
        call_done()
      .on 'error', call_done

  describe "Stream (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
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

    it 'should support data interface', (done) ->
      model_count = 0

      was_called = false
      call_done = (err) ->
        return if was_called; was_called = true
        assert.ok(!err, "No errors: #{err}")
        done()

      stream = Flat.stream()
      stream.on 'data', (model) -> model_count++
      stream.on 'error', call_done
      stream.on 'end', ->
        assert.equal(model_count, BASE_COUNT)
        call_done()

    it 'should support pipe interface', (done) ->
      pipeCheck(null, BASE_COUNT, done)

    it 'should support pipe interface with query (name)', (done) ->
      Flat.cursor({$one: true}).toModels (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        pipeCheck({name: model.get('name')}, 1, done)

    it 'should support pipe interface with query (limit)', (done) ->
      pipeCheck({$limit: 2}, 2, done)

    it 'should support pipe interface with query (limit + offset)', (done) ->
      pipeCheck({$limit: 2, $offset: BASE_COUNT-1}, 1, done)

    it 'should support pipe interface with transform', (done) ->
      was_called = false
      call_done = (err) ->
        return if was_called; was_called = true
        assert.ok(!err, "No errors: #{err}")
        done()

      filter = true
      Flat.stream()
        .pipe(new Filter((model) -> return filter = !filter))
        .pipe(counter = new Counter())
        .on 'finish', ->
          assert.equal(counter.count, Math.floor(BASE_COUNT/2))
          call_done()
        .on 'error', call_done
