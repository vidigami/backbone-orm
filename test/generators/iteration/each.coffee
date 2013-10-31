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

  ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: BASE_SCHEMA
    sync: SYNC(Flat)

  describe "Model.each (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure model cache
      queue.defer (callback) -> QueryCache.configure({enabled: !!options.query_cache, verbose: false}).reset(callback) # configure query cache

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback)

      queue.await done

    describe "Queries", ->

      it 'callback for all models', (done) ->
        processed_count = 0

        Flat.each ((model, callback) ->
            assert.ok(!!model, 'model returned')
            processed_count++
            callback()
          ),
          (err) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(BASE_COUNT, processed_count)
            done()

      it 'callback for queried models', (done) ->
        Flat.findOne (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!model, 'model returned')

          processed_count = 0

          Flat.each {name: model.get('name')},
            ((model, callback) ->
              assert.ok(!!model, 'model returned')
              processed_count++
              callback()
            ),
            (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(1, processed_count)
              done()

      it 'callback with limit and offset', (done) ->
        processed_count = 0

        Flat.each {$limit: 10, $offset: BASE_COUNT-3},
          ((model, callback) ->
            assert.ok(!!model, 'model returned')
            processed_count++
            callback()
          ),
          (err) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(3, processed_count)
            done()

      it 'callback for queried models with limit and offset', (done) ->
        Flat.findOne (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!model, 'model returned')

          processed_count = 0

          Flat.each {name: model.get('name'), $limit: 10, $offset: 0},
            ((model, callback) ->
              assert.ok(!!model, 'model returned')
              processed_count++
              callback()
            ),
            (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(1, processed_count)
              done()

    describe "JSON or Models", ->

      it 'Default is models', (done) ->
        processed_count = 0

        Flat.each ((model, callback) ->
            assert.ok(!!model, 'model returned')
            assert.ok(model instanceof Backbone.Model, 'is a model')
            processed_count++
            callback()
          ),
          (err) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(BASE_COUNT, processed_count)
            done()

      it 'Non-json is models', (done) ->
        processed_count = 0

        Flat.each {$each: {json: false}}, ((model, callback) ->
            assert.ok(!!model, 'model returned')
            assert.ok(model instanceof Backbone.Model, 'is a model')
            processed_count++
            callback()
          ),
          (err) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(BASE_COUNT, processed_count)
            done()

      it 'Can request json', (done) ->
        processed_count = 0

        Flat.each {$each: {json: true}}, ((model, callback) ->
            assert.ok(!!model, 'model returned')
            assert.ok(not (model instanceof Backbone.Model), 'is not a model')
            assert.ok(model.name, 'has a name')
            processed_count++
            callback()
          ),
          (err) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(BASE_COUNT, processed_count)
            done()

    describe "Threads", ->
      it 'Default is Infinite threads', (done) ->
        processed_count = 0
        results = []

        Flat.each ((model, callback) ->
            assert.ok(!!model, 'model returned')
            processed_count++
            _.delay (-> results.push(processed_count); callback()), 10
          ),
          (err) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(BASE_COUNT, processed_count)
            assert.deepEqual(results, _.map([1..BASE_COUNT], -> BASE_COUNT))
            done()

      it 'Can process one at a time', (done) ->
        processed_count = 0
        results = []

        Flat.each {$each: {threads: 1}}, ((model, callback) ->
            assert.ok(!!model, 'model returned')
            processed_count++
            _.delay (-> results.push(processed_count); callback()), 10
          ),
          (err) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(BASE_COUNT, processed_count)
            assert.deepEqual(results, [1..BASE_COUNT])
            done()
