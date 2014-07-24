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

  describe "Many casing #{options.$parameter_tags or ''}#{options.$tags}", ->
    Reverse = Owner = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Reverse extends Backbone.Model
        model_name: 'Reverse'
        urlRoot: "#{DATABASE_URL}/many_to_many_reverses"
        schema: _.defaults({
          owners: -> ['HasMany', Owner]
        }, BASE_SCHEMA)
        sync: SYNC(Reverse)

      class Owner extends Backbone.Model
        model_name: 'Owner'
        urlRoot: "#{DATABASE_URL}/many_to_many_owners"
        schema: _.defaults({
          reverses: -> ['has_many', Reverse]
        }, BASE_SCHEMA)
        sync: SYNC(Owner)

    after (callback) -> Utils.resetSchemas [Reverse, Owner], callback

    beforeEach (callback) ->
      MODELS = {}

      queue = new Queue(1)
      queue.defer (callback) -> Utils.resetSchemas [Reverse, Owner], callback
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverses_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owners_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err)

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.save {reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]}, callback

        save_queue.await callback

      queue.await callback

    it 'Handles a get query for a hasMany and hasMany two sided relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ifError(err)
        assert.ok(test_model, 'found model')
        test_model.get 'reverses', (err, reverses) ->
          assert.ifError(err)
          assert.ok(reverses.length, 'found related reverses')
          if test_model.relationIsEmbedded('reverses')
            assert.deepEqual(test_model.toJSON().reverses[0], reverses[0].toJSON(), "Serialized embedded. Expected: #{test_model.toJSON().reverses}. Actual: #{reverses[0].toJSON()}")
          else
            assert.deepEqual(test_model.get('reverse_ids')[0], reverses[0].id, "Serialized id only. Expected: #{test_model.get('reverse_ids')[0]}. Actual: #{reverses[0].id}")
          reverse = reverses[0]

          reverse.get 'owners', (err, owners) ->
            assert.ifError(err)
            assert.ok(owners.length, 'found related models')

            owner = _.find(owners, (test) -> test_model.id is test.id)
            owner_index = _.indexOf(owners, owner)
            if reverse.relationIsEmbedded('owners')
              assert.deepEqual(reverse.toJSON().owner_ids[owner_index], owner.id, "Serialized embedded. Expected: #{reverse.toJSON().owner_ids[owner_index]}. Actual: #{owner.id}")
            else
              assert.deepEqual(reverse.get('owner_ids')[owner_index], owner.id, "Serialized id only. Expected: #{reverse.get('owner_ids')[owner_index]}. Actual: #{owner.id}")
            assert.ok(!!owner, 'found owner')

            if Owner.cache
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "\nExpected: #{JSONUtils.stringify(test_model.toJSON())}\nActual: #{JSONUtils.stringify(test_model.toJSON())}")
            else
              assert.equal(test_model.id, owner.id, "\nExpected: #{test_model.id}\nActual: #{owner.id}")
            done()

