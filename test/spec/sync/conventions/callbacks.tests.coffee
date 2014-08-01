assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "Callbacks #{options.$parameter_tags or ''}#{options.$tags} @callbacks", ->
    Flat = Flats = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

      class Flats extends Backbone.Collection
        url: "#{DATABASE_URL}/flats"
        model: Flat
        sync: SYNC(Flats)

    after (callback) -> Utils.resetSchemas [Flat], callback

    beforeEach (callback) ->
      Utils.resetSchemas [Flat], (err) ->
        return callback(err) if err

        Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, callback

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
