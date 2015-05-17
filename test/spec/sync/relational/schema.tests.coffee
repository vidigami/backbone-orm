assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed and not options.sync.capabilities(options.database_url or '').embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "Schema #{options.$parameter_tags or ''}#{options.$tags} @schema", ->
    Flat = Reverse = Owner = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        model_name: 'Flat'
        urlRoot: "#{DATABASE_URL}/one_flats"
        schema: _.defaults({
          owner: -> ['hasOne', Owner]
        }, BASE_SCHEMA)
        cat: (field, meow, callback) -> callback(null, @get(field) + meow)
        sync: SYNC(Flat)

      class Reverse extends Backbone.Model
        model_name: 'Reverse'
        urlRoot: "#{DATABASE_URL}/one_reverses"
        schema: _.defaults({
          owner: -> ['belongsTo', Owner]
        }, BASE_SCHEMA)
        sync: SYNC(Reverse)

      class Owner extends Backbone.Model
        model_name: 'Owner'
        urlRoot: "#{DATABASE_URL}/one_owners"
        schema: _.defaults({
          flat: -> ['belongsTo', Flat, embed: options.embed]
          reverses: -> ['hasMany', Reverse]
        }, BASE_SCHEMA)
        cat: (field, meow, callback) -> callback(null, @get(field) + meow)
        sync: SYNC(Owner)

    after (callback) -> Utils.resetSchemas [Flat, Reverse, Owner], callback

    beforeEach (callback) ->
      MODELS = {}

      queue = new Queue(1)
      queue.defer (callback) -> Utils.resetSchemas [Flat, Reverse, Owner], callback
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owner_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err)

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.set({
              flat: MODELS.flat.pop()
              reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]
            })
            owner.save callback

        save_queue.await callback

      queue.await callback

    it 'type for models and id attribute', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        assert.ok(!!test_model.schema().type('id'), 'has type for id')
        assert.ok(test_model.schema().type('flat') is Flat, 'has type for flat')
        assert.ok(test_model.schema().type('reverses') is Reverse, 'has type for reverses')

        done()

    it 'JSONUtils.querify converts types correctly for nested models', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        query = {id: "#{test_model.id}", flat_id: "#{test_model.get('flat_id')}"}
        assert.ok(query.id); assert.ok(query.flat_id)

        assert.deepEqual(JSONUtils.parse(query), {id: "#{test_model.id}", flat_id: "#{test_model.get('flat_id')}"}, 'no model for lookup')
        if test_model.schema().type('id') isnt '_raw'
          assert.deepEqual(JSONUtils.parse(query, Owner), {id: test_model.id, flat_id: test_model.get('flat_id')}, 'with model for lookup')
        done()
