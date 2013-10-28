util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require '../../../src/queue'

ModelCache = require('../../../src/cache/singletons').ModelCache
QueryCache = require('../../../src/cache/singletons').QueryCache
Fabricator = require '../../fabricator'
Utils = require '../../../src/utils'

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure(if options.cache then {max: 100} else null).hardReset() # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat)

  class Flats extends Backbone.Collection
    url: "#{DATABASE_URL}/flats"
    model: Flat
    sync: SYNC(Flats)

  describe "Callbacks (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

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

    it 'Model.save (null, options)', (done) ->
      flat = new Flat({name: 'Bob'})
      flat.save null, {
        success: (model) ->
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: flat.id})
          model.fetch (err, flat) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()
      }

    it 'Model.save (attrs, options)', (done) ->
      flat = new Flat({name: 'Bob'})
      flat.save {}, {
        success: (model) ->
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: flat.id})
          model.fetch (err, flat) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()
      }

    it 'Model.save (callback)', (done) ->
      flat = new Flat({name: 'Bob'})
      flat.save (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        model = new Flat({id: flat.id})
        model.fetch (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(flat, model, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')
          done()

    it 'Model.save (attrs, callback)', (done) ->
      flat = new Flat()
      flat.save {name: 'Bob'}, (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        model = new Flat({id: flat.id})
        model.fetch (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(flat, model, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')
          done()

    it 'Model.save (attrs, options, callback)', (done) ->
      flat = new Flat()
      flat.save {name: 'Bob'}, {}, (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        model = new Flat({id: flat.id})
        model.fetch (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(flat, model, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')
          done()

    it 'Model.save (key, value, options, callback)', (done) ->
      flat = new Flat()
      flat.save 'name', 'Bob', {}, (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        model = new Flat({id: flat.id})
        model.fetch (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(flat, model, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')
          done()

    it 'Model.destroy (no options)', (done) ->
      flat = new Flat({name: 'Bob'})
      flat.save (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        model = new Flat({id: model_id = flat.id})
        model.fetch (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(flat, model, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')

          flat.destroy (err) ->
            assert.ok(!err, "No errors: #{err}")
            model = new Flat({id: model_id})
            model.fetch (err) ->
              assert.ok(err, "Model not found: #{err}")
              done()

    it 'Model.destroy (with options)', (done) ->
      flat = new Flat({name: 'Bob'})
      flat.save (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        model = new Flat({id: model_id = flat.id})
        model.fetch (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(flat, model, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')

          flat.destroy {}, (err) ->
            assert.ok(!err, "No errors: #{err}")
            model = new Flat({id: model_id})
            model.fetch (err) ->
              assert.ok(err, "Model not found: #{err}")
              done()

    it 'Model.fetch (no options)', (done) ->
      flat = new Flat({name: 'Bob'})
      flat.save (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        model = new Flat({id: flat.id})
        model.fetch (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(flat, model, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')
          done()

    it 'Model.fetch (with options)', (done) ->
      flat = new Flat({name: 'Bob'})
      flat.save (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        model = new Flat({id: flat.id})
        model.fetch {}, (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(flat, model, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')
          done()

    it 'Collection.fetch (no options)', (done) ->
      flat = new Flat({name: 'Bob'})
      flat.save (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        flats = new Flats()
        flats.fetch (err) ->
          assert.ok(!err, "No errors: #{err}")
          model = flats.get(flat.id)
          assert.equal(flat.id, model.id, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')
          done()

    it 'Collection.fetch (with options)', (done) ->
      flat = new Flat({name: 'Bob'})
      flat.save (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(flat, model, 'returned the model')

        flats = new Flats()
        flats.fetch {}, (err) ->
          assert.ok(!err, "No errors: #{err}")
          model = flats.get(flat.id)
          assert.equal(flat.id, model.id, 'returned the model')
          assert.equal(flat.get('name'), 'Bob', 'name matches')
          done()
