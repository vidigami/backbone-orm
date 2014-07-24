assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "hasMany #{options.$parameter_tags or ''}#{options.$tags}", ->
    Flat = Reverse = ForeignReverse = Owner = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}
      BackboneORM.configure {naming_conventions: 'classify'}

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

      class Reverse extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/reverses"
        schema: _.defaults({
          Owner: -> ['belongsTo', Owner]
          AnotherOwner: -> ['belongsTo', Owner, as: 'MoreReverses']
        }, BASE_SCHEMA)
        sync: SYNC(Reverse)

      class ForeignReverse extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/foreign_reverses"
        schema: _.defaults({
          Owner: -> ['belongsTo', Owner, foreign_key: 'ownerish_id']
        }, BASE_SCHEMA)
        sync: SYNC(ForeignReverse)

      class Owner extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/owners"
        schema: _.defaults({
          Flats: -> ['hasMany', Flat]
          Reverses: -> ['hasMany', Reverse]
          MoreReverses: -> ['hasMany', Reverse, as: 'AnotherOwner']
          ForeignReverses: -> ['hasMany', ForeignReverse]
        }, BASE_SCHEMA)
        sync: SYNC(Owner)

    after (callback) ->
      BackboneORM.configure({naming_conventions: 'default'})
      Utils.resetSchemas [Flat, Reverse, ForeignReverse, Owner], callback

    beforeEach (callback) ->
      relation = Owner.relation('Reverses')
      delete relation.virtual
      MODELS = {}

      queue = new Queue(1)
      queue.defer (callback) -> Utils.resetSchemas [Flat, Reverse, ForeignReverse, Owner], callback
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create Flat, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.more_reverse = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create ForeignReverse, BASE_COUNT, {
          name: Fabricator.uniqueId('foreign_reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.foreign_reverse = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owner_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err)

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue(1)

        link_tasks = []
        for owner in MODELS.owner
          link_task =
            Owner: owner
            values:
              Flats: [MODELS.flat.pop(), MODELS.flat.pop()]
              Reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]
              MoreReverses: [MODELS.more_reverse.pop(), MODELS.more_reverse.pop()]
              ForeignReverses: [MODELS.foreign_reverse.pop()]
          link_tasks.push(link_task)

        for link_task in link_tasks then do (link_task) -> save_queue.defer (callback) ->
          link_task.Owner.set(link_task.values)
          link_task.Owner.save callback

        save_queue.await callback

      queue.await callback

    it 'Can fetch and serialize a custom foreign key', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'ForeignReverses', (err, related_models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(1, related_models.length, "found related models. Expected: #{1}. Actual: #{related_models.length}")

          for related_model in related_models
            related_json = related_model.toJSON()
            assert.equal(test_model.id, related_json.ownerish_id, "Serialized the foreign id. Expected: #{test_model.id}. Actual: #{related_json.ownerish_id}")
          done()

    it 'Can create a model and load a related model by id (hasMany)', (done) ->
      Reverse.cursor({$values: 'id'}).limit(4).toJSON (err, reverse_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, reverse_ids.length, "found 4 reverses. Actual: #{reverse_ids.length}")

        new_model = new Owner()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({Reverses: reverse_ids})
          new_model.get 'Reverses', (err, reverses) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(4, reverses.length, "found 4 related model. Actual: #{reverses.length}")
            assert.equal(_.difference(reverse_ids, (test.id for test in reverses)).length, 0, "expected owners: #{_.difference(reverse_ids, (test.id for test in reverses))}")
            done()

    it 'Can create a model and load a related model by id (hasMany)', (done) ->
      Reverse.cursor({$values: 'id'}).limit(4).toJSON (err, reverse_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, reverse_ids.length, "found 4 reverses. Actual: #{reverse_ids.length}")

        new_model = new Owner()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({reverse_ids: reverse_ids})
          new_model.get 'Reverses', (err, reverses) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(4, reverses.length, "found 4 related model. Actual: #{reverses.length}")
            assert.equal(_.difference(reverse_ids, (test.id for test in reverses)).length, 0, "expected owners: #{_.difference(reverse_ids, (test.id for test in reverses))}")
            done()

    it 'Can create a model and load a related model by id (belongsTo)', (done) ->
      Owner.cursor({$values: 'id'}).limit(4).toJSON (err, owner_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, owner_ids.length, "found 4 owners. Actual: #{owner_ids.length}")

        new_model = new Reverse()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({Owner: owner_ids[0]})
          new_model.get 'Owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'loaded a model')
            assert.equal(owner_ids[0], owner.id, "loaded correct model. Expected: #{owner_ids[0]}. Actual: #{owner.id}")
            done()

    it 'Can create a model and load a related model by id (belongsTo)', (done) ->
      Owner.cursor({$values: 'id'}).limit(4).toJSON (err, owner_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, owner_ids.length, "found 4 owners. Actual: #{owner_ids.length}")

        new_model = new Reverse()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({owner_id: owner_ids[0]})
          new_model.get 'Owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'loaded a model')
            assert.equal(owner_ids[0], owner.id, "loaded correct model. Expected: #{owner_ids[0]}. Actual: #{owner.id}")
            done()
