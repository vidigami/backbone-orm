assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if not options.sync.capabilities(options.database_url or '').dynamic

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync

  describe "Dynamic Attributes Functionality #{options.$tags} @dynamic", ->
    Model = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Model extends Backbone.Model
        url: "#{DATABASE_URL}/models"
        sync: SYNC(Model)

    after (callback) -> Utils.resetSchemas [Model], callback
    beforeEach (callback) -> Utils.resetSchemas [Model], callback

    # TODO: these fail when the model cache is enabled
    describe 'unset', ->
      it 'should unset an attribute', (done) ->
        model = new Model({name: 'Bob', type: 'thing'})
        model.save (err) ->
          assert.ok(!err, "No errors: #{err}")

          Model.findOne model.id, (err, saved_model) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(!!saved_model, "Found model: #{model.id}")
            assert.deepEqual(model.toJSON(), saved_model.toJSON(), "1 Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")

            # unset and confirm different instances
            model.unset('type')
            assert.ok(_.isUndefined(model.get('type')), "Attribute was unset")
            if options.cache
              assert.deepEqual(model.toJSON(), saved_model.toJSON(), "2 Not Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")
            else
              assert.notDeepEqual(model.toJSON(), saved_model.toJSON(), "2 Not Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")
            model.save (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(_.isUndefined(model.get('type')), "Attribute is still unset")

              Model.findOne model.id, (err, saved_model) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!!saved_model, "Found model: #{model.id}")
                assert.ok(_.isUndefined(saved_model.get('type')), "Attribute was unset")

                assert.deepEqual(model.toJSON(), saved_model.toJSON(), "3 Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")

                # try resetting
                model.set({type: 'dynamic'})
                assert.ok(!_.isUndefined(model.get('type')), "Attribute was set")
                if options.cache
                  assert.deepEqual(model.toJSON(), saved_model.toJSON(), "4 Not Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")
                else
                  assert.notDeepEqual(model.toJSON(), saved_model.toJSON(), "4 Not Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")
                model.save (err) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(!_.isUndefined(model.get('type')), "Attribute is still set")

                  Model.findOne model.id, (err, saved_model) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!!saved_model, "Found model: #{model.id}")
                    assert.ok(!_.isUndefined(saved_model.get('type')), "Attribute was set")

                    assert.deepEqual(model.toJSON(), saved_model.toJSON(), "5 Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")

                    done()

      it 'should unset two attributes', (done) ->
        model = new Model({name: 'Bob', type: 'thing', direction: 'north'})
        model.save (err) ->
          assert.ok(!err, "No errors: #{err}")

          Model.findOne model.id, (err, saved_model) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(!!saved_model, "Found model: #{model.id}")
            assert.deepEqual(model.toJSON(), saved_model.toJSON(), "1 Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")

            # unset and confirm different instances
            model.unset('type')
            model.unset('direction')
            assert.ok(_.isUndefined(model.get('type')), "Attribute was unset")
            assert.ok(_.isUndefined(model.get('direction')), "Attribute was unset")
            if options.cache
              assert.deepEqual(model.toJSON(), saved_model.toJSON(), "2 Not Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")
            else
              assert.notDeepEqual(model.toJSON(), saved_model.toJSON(), "2 Not Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")
            model.save (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(_.isUndefined(model.get('type')), "Attribute 'type' is still unset")
              assert.ok(_.isUndefined(model.get('direction')), "Attribute 'direction' is still unset")

              Model.findOne model.id, (err, saved_model) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!!saved_model, "Found model: #{model.id}")
                assert.ok(_.isUndefined(saved_model.get('type')), "Attribute was unset")
                assert.ok(_.isUndefined(saved_model.get('direction')), "Attribute was unset")

                assert.deepEqual(model.toJSON(), saved_model.toJSON(), "3 Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")

                # try resetting
                model.set({type: 'dynamic', direction: 'south'})
                assert.ok(!_.isUndefined(model.get('type')), "Attribute was set")
                assert.ok(!_.isUndefined(model.get('direction')), "Attribute was set")
                if options.cache
                  assert.deepEqual(model.toJSON(), saved_model.toJSON(), "4 Not Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")
                else
                  assert.notDeepEqual(model.toJSON(), saved_model.toJSON(), "4 Not Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")
                model.save (err) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(!_.isUndefined(model.get('type')), "Attribute is still set")
                  assert.ok(!_.isUndefined(model.get('direction')), "Attribute is still set")

                  Model.findOne model.id, (err, saved_model) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!!saved_model, "Found model: #{model.id}")
                    assert.ok(!_.isUndefined(saved_model.get('type')), "Attribute 'type' was set")
                    assert.ok(!_.isUndefined(saved_model.get('direction')), "Attribute 'direction' was set")

                    assert.deepEqual(model.toJSON(), saved_model.toJSON(), "5 Expected: #{JSONUtils.stringify(model.toJSON())}. Actual: #{JSONUtils.stringify(saved_model.toJSON())}")

                    done()
