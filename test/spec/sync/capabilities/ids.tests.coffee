assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed
  return if not options.sync.capabilities(options.database_url or '').manual_ids

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync

  describe "Ids #{options.$parameter_tags or ''}#{options.$tags} @ids", ->
    Flat = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      schema = JSONUtils.deepClone(BASE_SCHEMA, 3)
      schema.id or= []
      if schema.id.length and _.isObject(type = schema.id[schema.id.length-1]) then type.manual = true else schema.id.push({manual: true})

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: schema
        sync: SYNC(Flat)

    beforeEach (callback) -> Utils.resetSchemas [Flat], callback

    describe 'manual id option', ->
      it 'should fail to save if you do not provide an id', (done) ->
        model = new Flat({name: 'Bob'})
        model.save (err) ->
          assert.ok(err, 'should not save if missing an id')
          done()

      it 'should save if provide an id (number)', (done) ->
        model = new Flat({id: +_.uniqueId(), name: 'Bob'})
        model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          done()

      it 'should save if provide an id (string)', (done) ->
        model = new Flat({id: _.uniqueId('manual_id_'), name: 'Bob'})
        model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          done()

      it 'should fail to save if you delete the id after saving', (done) ->
        model = new Flat({id: _.uniqueId(), name: 'Bob'})
        model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          model.save {id: null}, (err) ->
            assert.ok(err, 'should not save if missing an id')
            done()

      it 'should sort by id', (done) ->
        (new Flat({id: 3, name: 'Bob'})).save (err) ->
          assert.ok(!err, "No errors: #{err}")

          (new Flat({id: 1, name: 'Bob'})).save (err) ->
            assert.ok(!err, "No errors: #{err}")

            Flat.cursor().sort('id').toModels (err, models) ->
              assert.ok(!err, "No errors: #{err}")
              ids = (model.id for model in models)
              sorted_ids = _.clone(ids).sort()
              assert.deepEqual(ids, sorted_ids, "Models were returned in sorted order")
              done()
