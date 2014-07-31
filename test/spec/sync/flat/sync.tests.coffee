assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "Backbone Sync #{options.$parameter_tags or ''}#{options.$tags} @sync", ->
    Flat = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

    after (callback) -> Utils.resetSchemas [Flat], callback

    beforeEach (callback) ->
      Utils.resetSchemas [Flat], (err) ->
        return callback(err) if err

        Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, callback

    it 'saves a model and assigns an id', (done) ->
      bob = new Flat({name: 'Bob'})
      assert.equal(bob.get('name'), 'Bob', 'name before save is Bob')
      assert.ok(!bob.id, 'id before save doesn\'t exist')

      bob.save (err) ->
        assert.ifError(err)

        assert.equal(bob.get('name'), 'Bob', 'name after save is Bob')
        assert.ok(!!bob.id, 'id after save is assigned')
        done()

    it 'fetches model data', (done) ->
      Flat.findOne (err, model) ->
        assert.ifError(err)
        assert.ok(!!model, 'got model')

        new_model = new Flat({id: model.id})
        new_model.fetch (err) ->
          assert.ifError(err)
          assert.deepEqual(model.toJSON(), new_model.toJSON(), "\nExpected: #{JSONUtils.stringify(model.toJSON())}\nActual: #{JSONUtils.stringify(new_model.toJSON())}")
          done()

    it 'destroys a model', (done) ->
      Flat.findOne (err, model) ->
        assert.ifError(err)
        assert.ok(!!model, 'got model')
        model_id = model.id

        model.destroy (err) ->
          assert.ifError(err)

          Flat.find model_id, (err, model) ->
            assert.ifError(err)
            assert.ok(!model, "Model not found after destroy")
            done()
