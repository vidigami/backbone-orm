assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM or require?('backbone-orm')
_ = BackboneORM._; Backbone = BackboneORM.Backbone
Queue = BackboneORM.Queue
ModelCache = BackboneORM.CacheSingletons.ModelCache
Fabricator = BackboneORM.Fabricator

option_sets = window?.__test__option_sets or require?('../../option_sets')
parameters = __test__parameters if __test__parameters?
_.each option_sets, exports = (options) ->
  return if options.embed or options.query_cache
  options = _.extend({}, options, parameters) if parameters

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: BASE_SCHEMA
    sync: SYNC(Flat)

  class Flats extends Backbone.Collection
    url: "#{DATABASE_URL}/flats"
    model: Flat
    sync: SYNC(Flats)

  describe "Callbacks #{options.$parameter_tags or ''}#{options.$tags}", ->

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

    ##############################
    # No Callbacks (Options)
    ##############################

    describe "No callbacks", ->

      it 'Model.save (null, options) - non callback', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save null, {
          success: (model) ->
            assert.equal(flat, model, 'returned the model')

            model = new Flat({id: flat.id})
            model.fetch (err, flat) ->
              assert.ifError(err)
              assert.equal(flat, model, 'returned the model')
              assert.equal(flat.get('name'), 'Bob', 'name matches')
              done()
          error: (err) ->
            assert.ifError(err and false)
        }

      it 'Model.save (attrs, options) - non callback', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save {}, {
          success: (model) ->
            assert.equal(flat, model, 'returned the model')

            model = new Flat({id: flat.id})
            model.fetch (err, flat) ->
              assert.ifError(err)
              assert.equal(flat, model, 'returned the model')
              assert.equal(flat.get('name'), 'Bob', 'name matches')
              done()
          error: (err) ->
            assert.ifError(err and false)
        }

      it 'Model.save (key, value, options) - non callback', (done) ->
        flat = new Flat()
        flat.save 'name', 'Bob', {
          success: (model) ->
            assert.equal(flat, model, 'returned the model')

            model = new Flat({id: flat.id})
            model.fetch (err, flat) ->
              assert.ifError(err)
              assert.equal(flat, model, 'returned the model')
              assert.equal(flat.get('name'), 'Bob', 'name matches')
              done()
          error: (err) ->
            assert.ifError(err and false)
        }

      it 'Model.destroy (options) - non callback', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: model_id = flat.id})
          model.fetch (err, flat) ->
            assert.ifError(err)
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')

            flat.destroy {
              success: ->
                model = new Flat({id: model_id})
                model.fetch (err) ->
                  assert.ok(err, "Model not found: #{err}")
                  done()
              error: (err) ->
                assert.ifError(err and false)
            }

      it 'Model.fetch (options) - non callback', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: flat.id})
          flat.fetch {
            success: (model) ->
              assert.equal(flat, model, 'returned the model')
              assert.equal(flat.get('name'), 'Bob', 'name matches')
              done()
            error: (err) ->
              assert.ifError(err and false)
          }

      it 'Collection.fetch (options)  - non callback', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          flats = new Flats()
          flats.fetch {
            success: ->
              model = flats.get(flat.id)
              assert.equal(flat.id, model.id, 'returned the model')
              assert.equal(flat.get('name'), 'Bob', 'name matches')
              done()
            error: (err) ->
              assert.ifError(err and false)
          }

    ##############################
    # Callbacks
    ##############################

    describe "Callbacks", ->

      it 'Model.save (callback)', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: flat.id})
          model.fetch (err, flat) ->
            assert.ifError(err)
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()

      it 'Model.save (attrs, callback)', (done) ->
        flat = new Flat()
        flat.save {name: 'Bob'}, (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: flat.id})
          model.fetch (err, flat) ->
            assert.ifError(err)
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()

      it 'Model.save (attrs, options, callback)', (done) ->
        flat = new Flat()
        flat.save {name: 'Bob'}, {}, (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: flat.id})
          model.fetch (err, flat) ->
            assert.ifError(err)
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()

      it 'Model.save (key, value, options, callback)', (done) ->
        flat = new Flat()
        flat.save 'name', 'Bob', {}, (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: flat.id})
          model.fetch (err, flat) ->
            assert.ifError(err)
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()

      it 'Model.destroy (no options)', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: model_id = flat.id})
          model.fetch (err, flat) ->
            assert.ifError(err)
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')

            flat.destroy (err) ->
              assert.ifError(err)
              model = new Flat({id: model_id})
              model.fetch (err) ->
                assert.ok(err, "Model not found: #{err}")
                done()

      it 'Model.destroy (with options)', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: model_id = flat.id})
          model.fetch (err, flat) ->
            assert.ifError(err)
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')

            flat.destroy {}, (err) ->
              assert.ifError(err)
              model = new Flat({id: model_id})
              model.fetch (err) ->
                assert.ok(err, "Model not found: #{err}")
                done()

      it 'Model.fetch (no options)', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: flat.id})
          model.fetch (err, flat) ->
            assert.ifError(err)
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()

      it 'Model.fetch (with options)', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          model = new Flat({id: flat.id})
          model.fetch {}, (err, flat) ->
            assert.ifError(err)
            assert.equal(flat, model, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()

      it 'Collection.fetch (no options)', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          flats = new Flats()
          flats.fetch (err) ->
            assert.ifError(err)
            model = flats.get(flat.id)
            assert.equal(flat.id, model.id, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()

      it 'Collection.fetch (with options)', (done) ->
        flat = new Flat({name: 'Bob'})
        flat.save (err, model) ->
          assert.ifError(err)
          assert.equal(flat, model, 'returned the model')

          flats = new Flats()
          flats.fetch {}, (err) ->
            assert.ifError(err)
            model = flats.get(flat.id)
            assert.equal(flat.id, model.id, 'returned the model')
            assert.equal(flat.get('name'), 'Bob', 'name matches')
            done()
