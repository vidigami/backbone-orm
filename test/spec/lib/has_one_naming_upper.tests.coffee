assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM
{inflection} = BackboneORM.modules

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "One naming #{options.$parameter_tags or ''}#{options.$tags}", ->
    Flat = Reverse = Owner = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class UpperCaseConventions extends BackboneORM.BaseConvention
        @attribute: (model_name, plural) ->
          inflection[if plural then 'pluralize' else 'singularize'](model_name).toUpperCase()
        @foreignKey: (model_name, plural) ->
          BackboneORM.BaseConvention.foreignKey(model_name.toLowerCase(), plural)
      BackboneORM.configure({naming_conventions: UpperCaseConventions})

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

      class Reverse extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/reverses"
        schema: _.defaults({
          OWNER: -> ['belongs_to', Owner]
        }, BASE_SCHEMA)
        sync: SYNC(Reverse)

      class Owner extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/owners"
        schema: _.defaults({
          FLAT: -> ['BelongsTo', Flat, embed: options.embed]
          REVERSE: -> ['has_one', Reverse]
        }, BASE_SCHEMA)
        sync: SYNC(Owner)

    after (callback) ->
      BackboneORM.configure({naming_conventions: 'default'})
      Utils.resetSchemas [Flat, Reverse, Owner], callback

    beforeEach (done) ->
      MODELS = {}

      queue = new Queue(1)
      queue.defer (callback) -> Utils.resetSchemas [Flat, Reverse, Owner], callback
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.FLAT = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Reverse, BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.REVERSE = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owner_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err)

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        reverses = MODELS.REVERSE.slice()
        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.save {FLAT: MODELS.FLAT.pop(), REVERSE: reverses.pop()}, callback

        save_queue.await callback

      queue.await done

    # TODO: delay the returning of memory models related models to test lazy loading properly
    it 'Fetches a relation from the store if not present', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ifError(err)
        assert.ok(test_model, 'found model')

        fetched_owner = new Owner({id: test_model.id})
        fetched_owner.fetch (err) ->
          assert.ifError(err)
          delete fetched_owner.attributes.REVERSE

          fetched_owner.get 'REVERSE', (err, reverse) ->
            assert.ifError(err)
            assert.ok(reverse, 'loaded the model lazily')
            assert.equal(reverse.get('owner_id'), test_model.id)
            done()
            # assert.equal(reverse, null, 'has not loaded the model initially')

    it 'Has an id loaded for a belongsTo and not for a hasOne relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ifError(err)
        assert.ok(test_model, 'found model')
        assert.ok(test_model.get('flat_id'), 'belongsTo id is loaded')
        # assert.ok(!test_model.get('reverse_id'), 'hasOne id is not loaded')
        done()

    it 'Handles a get query for a belongsTo relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ifError(err)
        assert.ok(test_model, 'found model')

        test_model.get 'FLAT', (err, flat) ->
          assert.ifError(err)
          assert.ok(flat, 'found related model')
          if test_model.relationIsEmbedded('FLAT')
            assert.deepEqual(test_model.toJSON().FLAT, flat.toJSON(), "Serialized embed. Expected: #{JSONUtils.stringify(test_model.toJSON().FLAT)}. Actual: #{JSONUtils.stringify(flat.toJSON())}")
          else
            assert.deepEqual(test_model.toJSON().flat_id, flat.id, "Serialized id only. Expected: #{test_model.toJSON().flat_id}. Actual: #{flat.id}")
          assert.equal(test_model.get('flat_id'), flat.id, "\nExpected: #{test_model.get('flat_id')}\nActual: #{flat.id}")
          done()

    it 'Can retrieve an id for a hasOne relation via async virtual method', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ifError(err)
        assert.ok(test_model, 'found model')
        test_model.get 'reverse_id', (err, id) ->
          assert.ifError(err)
          assert.ok(id, 'found id')
          done()

    it 'Handles a get query for a hasOne relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ifError(err)
        assert.ok(test_model, 'found model')

        test_model.get 'REVERSE', (err, reverse) ->
          assert.ifError(err)
          assert.ok(reverse, 'found related model')
          assert.equal(test_model.id, reverse.get('owner_id'), "\nExpected: #{test_model.id}\nActual: #{reverse.get('owner_id')}")
          assert.equal(test_model.id, reverse.toJSON().owner_id, "\nReverse toJSON has an owner_id. Expected: #{test_model.id}\nActual: #{reverse.toJSON().owner_id}")
          if test_model.relationIsEmbedded('REVERSE')
            assert.deepEqual(test_model.toJSON().REVERSE, reverse.toJSON(), "Serialized embed. Expected: #{JSONUtils.stringify(test_model.toJSON().REVERSE)}. Actual: #{JSONUtils.stringify(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_id, 'No reverese_id in owner json')
          done()

    it 'Handles a get query for a hasOne and belongsTo two sided relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ifError(err)
        assert.ok(test_model, 'found model')

        test_model.get 'REVERSE', (err, reverse) ->
          assert.ifError(err)
          assert.ok(reverse, 'found related model')
          assert.equal(test_model.id, reverse.get('owner_id'), "\nExpected: #{test_model.id}\nActual: #{reverse.get('owner_id')}")
          assert.equal(test_model.id, reverse.toJSON().owner_id, "\nReverse toJSON has an owner_id. Expected: #{test_model.id}\nActual: #{reverse.toJSON().owner_id}")
          if test_model.relationIsEmbedded('REVERSE')
            assert.deepEqual(test_model.toJSON().REVERSE, reverse.toJSON(), "Serialized embed. Expected: #{JSONUtils.stringify(test_model.toJSON().REVERSE)}. Actual: #{JSONUtils.stringify(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_id, 'No reverese_id in owner json')

          reverse.get 'OWNER', (err, owner) ->
            assert.ifError(err)
            assert.ok(owner, 'found original model')
            assert.deepEqual(reverse.toJSON().owner_id, owner.id, "Serialized id only. Expected: #{reverse.toJSON().owner_id}. Actual: #{owner.id}")

            if Owner.cache
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "\nExpected: #{JSONUtils.stringify(test_model.toJSON())}\nActual: #{JSONUtils.stringify(owner.toJSON())}")
            else
              assert.equal(test_model.id, owner.id, "\nExpected: #{test_model.id}\nActual: #{owner.id}")
            done()


    it 'Appends json for a related model', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ifError(err)
        assert.ok(test_model, 'found model')

        JSONUtils.renderRelated test_model, 'REVERSE', ['id', 'created_at'], (err, related_json) ->
          assert.ifError(err)
          assert.ok(related_json.id, "reverse has an id")
          assert.ok(related_json.created_at, "reverse has a created_at")
          assert.ok(!related_json.updated_at, "reverse doesn't have updated_at")

          JSONUtils.renderRelated test_model, 'FLAT', ['id', 'created_at'], (err, related_json) ->
            assert.ifError(err)

            assert.ok(related_json.id, "flat has an id")
            # assert.ok(related_json.created_at, "flat has a created_at")
            assert.ok(!related_json.updated_at, "flat doesn't have updated_at")
            done()
