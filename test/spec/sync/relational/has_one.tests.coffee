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

  PICK_KEYS = ['id', 'name']

  describe "hasOne #{options.$parameter_tags or ''}#{options.$tags} @has_one", ->
    Flat = Reverse = ForeignReverse = Owner = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        model_name: 'Flat'
        urlRoot: "#{DATABASE_URL}/one_flats"
        schema: _.defaults({
          owner: -> ['hasOne', Owner]
        }, BASE_SCHEMA)
        sync: SYNC(Flat)

      class Reverse extends Backbone.Model
        model_name: 'Reverse'
        urlRoot: "#{DATABASE_URL}/one_reverses"
        schema: _.defaults({
          owner: -> ['belongsTo', Owner]
          owner_as: -> ['belongsTo', Owner, as: 'reverse_as']
        }, BASE_SCHEMA)
        sync: SYNC(Reverse)

      class ForeignReverse extends Backbone.Model
        model_name: 'ForeignReverse'
        urlRoot: "#{DATABASE_URL}/one_foreign_reverses"
        schema: _.defaults({
          owner: -> ['belongsTo', Owner, foreign_key: 'ownerish_id']
        }, BASE_SCHEMA)
        sync: SYNC(ForeignReverse)

      class Owner extends Backbone.Model
        model_name: 'Owner'
        urlRoot: "#{DATABASE_URL}/one_owners"
        schema: _.defaults({
          flat: -> ['belongsTo', Flat, embed: options.embed]
          reverse: -> ['hasOne', Reverse]
          reverse_as: -> ['hasOne', Reverse, as: 'owner_as']
          foreign_reverse: -> ['hasOne', ForeignReverse]
        }, BASE_SCHEMA)
        sync: SYNC(Owner)

    after (callback) -> Utils.resetSchemas [Flat, Reverse, ForeignReverse, Owner], callback

    beforeEach (callback) ->
      relation = Owner.relation('flat')
      delete relation.virtual
      MODELS = {}
      queue = new Queue(1)

      queue.defer (callback) -> Utils.resetSchemas [Flat, Reverse, ForeignReverse, Owner], callback
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Reverse, BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err)
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
        save_queue = new Queue(1) # NOTE: save serially because we are including reverse_as in reverse over (overlap between saves)
        reversed_reverse = _.clone(MODELS.reverse).reverse()

        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.set({
              flat: MODELS.flat.pop()
              reverse: MODELS.reverse.pop()
              reverse_as: reversed_reverse.pop()
              foreign_reverse: MODELS.foreign_reverse.pop()
            })
            owner.save callback

        save_queue.await callback

      queue.await callback

    it 'Can fetch and serialize a custom foreign key', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'foreign_reverse', (err, related_model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(related_model, 'found related model')

          related_json = related_model.toJSON()
          assert.equal(test_model.id, related_json.ownerish_id, "Serialized the foreign id. Expected: #{test_model.id}. Actual: #{related_json.ownerish_id}")
          done()

    it 'Can create a model and load a related model by id (belongsTo)', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        flat_id = test_model.id
        new_model = new Owner({flat_id: flat_id})

        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")

          new_model.get 'flat', (err, flat) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(flat, 'found related model')
            assert.equal(flat_id, flat.id, 'Loaded model is correct')
            done()

    patchAddTests = (unload) ->
      it "Can manually add a relationship by related_id (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverse', (err, reverse) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(reverse, "loaded correct model.")

            Reverse.cursor({id: {$ne: reverse.id}, $one: true}).toJSON (err, another_reverse_json) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(another_reverse_json, "loaded another model.")
              assert.ok(reverse.id isnt another_reverse_json.id, "loaded a model with a different id.")

              if unload
                BackboneORM.model_cache.reset() # reset cache
                owner = new Owner({id: owner.id})
              owner.patchAdd 'reverse', another_reverse_json.id, (err) ->
                assert.ok(!err, "No errors: #{err}")
                updated_reverse = owner.get('reverse')
                assert.ok(updated_reverse.id is another_reverse_json.id, "Set the id. Expected: #{another_reverse_json.id}. Actual: #{updated_reverse.id}")

                owner.get 'reverse', (err, updated_reverse) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(updated_reverse, "loaded another model.")
                  assert.equal(updated_reverse.get('owner_id'), owner.id, "owner_id is correct.")

                  assert.ok(_.isEqual(_.pick(updated_reverse.toJSON(), PICK_KEYS), _.pick(another_reverse_json, PICK_KEYS)), "Set the id. Expected: #{JSONUtils.stringify(_.pick(another_reverse_json, PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(updated_reverse.toJSON(), PICK_KEYS))}")
                  done()

      it "Can manually add a relationship by related json (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverse', (err, reverse) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(reverse, "loaded correct model.")

            Reverse.cursor({id: {$ne: reverse.id}, $one: true}).toJSON (err, another_reverse_json) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(another_reverse_json, "loaded another model.")
              assert.ok(reverse.id isnt another_reverse_json.id, "loaded a model with a different id.")

              if unload
                BackboneORM.model_cache.reset() # reset cache
                owner = new Owner({id: owner.id})
              owner.patchAdd 'reverse', another_reverse_json, (err) ->
                assert.ok(!err, "No errors: #{err}")
                updated_reverse = owner.get('reverse')
                assert.ok(updated_reverse.id is another_reverse_json.id, "Set the id. Expected: #{another_reverse_json.id}. Actual: #{updated_reverse.id}")

                owner.get 'reverse', (err, updated_reverse) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(updated_reverse, "loaded another model.")
                  assert.equal(updated_reverse.get('owner_id'), owner.id, "owner_id is correct.")

                  assert.ok(_.isEqual(_.pick(updated_reverse.toJSON(), PICK_KEYS), _.pick(another_reverse_json, PICK_KEYS)), "Set the id. Expected: #{JSONUtils.stringify(_.pick(another_reverse_json, PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(updated_reverse.toJSON(), PICK_KEYS))}")
                  done()

      it "Can manually add a relationship by related model (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverse', (err, reverse) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(reverse, "loaded correct model.")

            Reverse.cursor({id: {$ne: reverse.id}}).toModel (err, another_reverse) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(another_reverse, "loaded another model.")
              assert.ok(reverse.id isnt another_reverse.id, "loaded a model with a different id.")

              if unload
                BackboneORM.model_cache.reset() # reset cache
                owner = new Owner({id: owner.id})
              owner.patchAdd 'reverse', another_reverse, (err) ->
                assert.ok(!err, "No errors: #{err}")
                updated_reverse = owner.get('reverse')
                assert.ok(updated_reverse.id is another_reverse.id, "Set the id. Expected: #{another_reverse.id}. Actual: #{updated_reverse.id}")

                owner.get 'reverse', (err, updated_reverse) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(updated_reverse, "loaded another model.")
                  assert.equal(updated_reverse.get('owner_id'), owner.id, "owner_id is correct.")

                  assert.ok(_.isEqual(_.pick(updated_reverse.toJSON(), PICK_KEYS), _.pick(another_reverse.toJSON(), PICK_KEYS)), "Set the id. Expected: #{JSONUtils.stringify(_.pick(another_reverse.toJSON(), PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(updated_reverse.toJSON(), PICK_KEYS))}")
                  done()

      it "Can manually add a relationship by related_id (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found reverse')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, "loaded correct model.")

            Owner.cursor({id: {$ne: owner.id}, $one: true}).toJSON (err, another_owner_json) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(another_owner_json, "loaded another model.")
              assert.ok(owner.id isnt another_owner_json.id, "loaded a model with a different id.")

              if unload
                BackboneORM.model_cache.reset() # reset cache
                reverse = new Reverse({id: reverse.id})
              reverse.patchAdd 'owner', another_owner_json.id, (err) ->
                assert.ok(!err, "No errors: #{err}")
                updated_owner = reverse.get('owner')
                assert.ok(updated_owner.id is another_owner_json.id, "Set the id. Expected: #{another_owner_json.id}. Actual: #{updated_owner.id}")

                reverse.get 'owner', (err, updated_owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(updated_owner, "loaded another model.")

                  assert.equal(updated_owner.get('reverse_id'), reverse.id, "reverse_id is correct.")
                  assert.ok(_.isEqual(_.pick(updated_owner.toJSON(), PICK_KEYS), _.pick(another_owner_json, PICK_KEYS)), "Set the id. Expected: #{JSONUtils.stringify(_.pick(another_owner_json, PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(updated_owner.toJSON(), PICK_KEYS))}")
                  done()

      it "Can manually add a relationship by related json (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found reverse')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, "loaded correct model.")

            Owner.cursor({id: {$ne: owner.id}, $one: true}).toJSON (err, another_owner_json) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(another_owner_json, "loaded another model.")
              assert.ok(owner.id isnt another_owner_json.id, "loaded a model with a different id.")

              if unload
                BackboneORM.model_cache.reset() # reset cache
                reverse = new Reverse({id: reverse.id})
              reverse.patchAdd 'owner', another_owner_json, (err) ->
                assert.ok(!err, "No errors: #{err}")
                updated_owner = reverse.get('owner')
                assert.ok(updated_owner.id is another_owner_json.id, "Set the id. Expected: #{another_owner_json.id}. Actual: #{updated_owner.id}")

                reverse.get 'owner', (err, updated_owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(updated_owner, "loaded another model.")

                  assert.equal(updated_owner.get('reverse_id'), reverse.id, "reverse_id is correct.")
                  assert.ok(_.isEqual(_.pick(updated_owner.toJSON(), PICK_KEYS), _.pick(another_owner_json, PICK_KEYS)), "Set the id. Expected: #{JSONUtils.stringify(_.pick(another_owner_json, PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(updated_owner.toJSON(), PICK_KEYS))}")
                  done()

      it "Can manually add a relationship by related model (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found reverse')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, "loaded correct model.")

            Owner.cursor({id: {$ne: owner.id}}).toModel (err, another_owner) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(another_owner, "loaded another model.")
              assert.ok(owner.id isnt another_owner.id, "loaded a model with a different id.")

              if unload
                BackboneORM.model_cache.reset() # reset cache
                reverse = new Reverse({id: reverse.id})
              reverse.patchAdd 'owner', another_owner, (err) ->
                assert.ok(!err, "No errors: #{err}")
                updated_owner = reverse.get('owner')
                assert.ok(updated_owner.id is another_owner.id, "Set the id. Expected: #{another_owner.id}. Actual: #{updated_owner.id}")

                reverse.get 'owner', (err, updated_owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(updated_owner, "loaded another model.")

                  assert.equal(updated_owner.get('reverse_id'), reverse.id, "reverse_id is correct.")
                  assert.ok(_.isEqual(_.pick(updated_owner.toJSON(), PICK_KEYS), _.pick(another_owner.toJSON(), PICK_KEYS)), "Set the id. Expected: #{JSONUtils.stringify(_.pick(another_owner.toJSON(), PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(updated_owner.toJSON(), PICK_KEYS))}")
                  done()

    patchAddTests(false)
    patchAddTests(true)

    patchRemoveTests = (unload) ->
      it "Can manually delete a relationship by related_id (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverse', (err, reverse) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(reverse, "loaded correct model.")

            destroyed_model = reverse
            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchRemove 'reverse', destroyed_model.id, (err) ->
              assert.ok(!err, "No errors: #{err}")

              assert.ok(!owner.get('reverse'), "destroyed in memory relationship.")

              owner.get 'reverse', (err, reverse) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!reverse, "loaded correct models.")

                Owner.findOne owner.id, (err, owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(owner, 'found owners')

                  owner.get 'reverse', (err, reverse) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!reverse, "loaded correct models.")
                    done()

      it "Can manually delete a relationship by related_json (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverse', (err, reverse) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(reverse, "loaded correct model.")

            destroyed_model = reverse
            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchRemove 'reverse', destroyed_model.toJSON(), (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!owner.get('reverse'), "destroyed in memory relationship.")

              owner.get 'reverse', (err, reverse) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!reverse, "loaded correct models.")

                Owner.findOne owner.id, (err, owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(owner, 'found owners')

                  owner.get 'reverse', (err, reverse) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!reverse, "loaded correct models.")
                    done()

      it "Can manually delete a relationship by related model (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverse', (err, reverse) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(reverse, "loaded correct model.")

            destroyed_model = reverse
            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchRemove 'reverse', destroyed_model, (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!owner.get('reverse'), "destroyed in memory relationship.")

              owner.get 'reverse', (err, reverse) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!reverse, "loaded correct models.")

                Owner.findOne owner.id, (err, owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(owner, 'found owners')

                  owner.get 'reverse', (err, reverse) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!reverse, "loaded correct models.")
                    done()

      it "Can manually delete a relationship by array related of model (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverse', (err, reverse) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(reverse, "loaded correct model.")

            destroyed_model = reverse
            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchRemove 'reverse', [destroyed_model], (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!owner.get('reverse'), "destroyed in memory relationship.")

              owner.get 'reverse', (err, reverse) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!reverse, "loaded correct models.")

                Owner.findOne owner.id, (err, owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(owner, 'found owners')

                  owner.get 'reverse', (err, reverse) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!reverse, "loaded correct models.")
                    done()

      it "Can manually delete a relationship by related_id (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found reverse')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, "loaded correct model")

            destroyed_model = owner
            if unload
              BackboneORM.model_cache.reset() # reset cache
              reverse = new Reverse({id: reverse.id})
            reverse.patchRemove 'owner', destroyed_model.id, (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!reverse.get('owner'), "destroyed in memory relationship.")

              reverse.get 'owner', (err, owner) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!owner, 'destroyed correct model')

                Reverse.findOne reverse.id, (err, reverse) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(reverse, 'found reverse')
                  assert.ok(!reverse.get('owner'), 'destroyed correct model')

                  reverse.get 'owner', (err, owner) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!owner, 'destroyed correct model')
                    done()

      it "Can manually delete a relationship by related_json (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found reverse')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, "loaded correct model")

            destroyed_model = owner
            if unload
              BackboneORM.model_cache.reset() # reset cache
              reverse = new Reverse({id: reverse.id})
            reverse.patchRemove 'owner', destroyed_model.toJSON(), (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!reverse.get('owner'), "destroyed in memory relationship.")

              reverse.get 'owner', (err, owner) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!owner, 'destroyed correct model')

                Reverse.findOne reverse.id, (err, reverse) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(reverse, 'found reverse')
                  assert.ok(!reverse.get('owner'), 'destroyed correct model')

                  reverse.get 'owner', (err, owner) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!owner, 'destroyed correct model')
                    done()

      it "Can manually delete a relationship by related_model (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found reverse')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, "loaded correct model")

            destroyed_model = owner
            if unload
              BackboneORM.model_cache.reset() # reset cache
              reverse = new Reverse({id: reverse.id})
            reverse.patchRemove 'owner', destroyed_model, (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!reverse.get('owner'), "destroyed in memory relationship.")

              reverse.get 'owner', (err, owner) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!owner, 'destroyed correct model')

                Reverse.findOne reverse.id, (err, reverse) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(reverse, 'found reverse')
                  assert.ok(!reverse.get('owner'), 'destroyed correct model')

                  reverse.get 'owner', (err, owner) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!owner, 'destroyed correct model')
                    done()

      it "Can manually delete a relationship by array of related_model (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found reverse')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, "loaded correct model")

            destroyed_model = owner
            if unload
              BackboneORM.model_cache.reset() # reset cache
              reverse = new Reverse({id: reverse.id})
            reverse.patchRemove 'owner', [destroyed_model], (err) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!reverse.get('owner'), "destroyed in memory relationship.")

              reverse.get 'owner', (err, owner) ->
                assert.ok(!err, "No errors: #{err}")
                assert.ok(!owner, 'destroyed correct model')

                Reverse.findOne reverse.id, (err, reverse) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(reverse, 'found reverse')
                  assert.ok(!reverse.get('owner'), 'destroyed correct model')

                  reverse.get 'owner', (err, owner) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(!owner, 'destroyed correct model')
                    done()

    patchRemoveTests(false)
    patchRemoveTests(true)

    it 'Can create a model and update the relationship (belongsTo)', (done) ->
      related_key = 'flat'
      related_id_accessor = 'flat_id'

      Owner.cursor().include(related_key).toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner_id = owner.id
        related = owner.get(related_key)
        related_id = related.id
        assert.ok(related, 'included related')

        (attributes = {})[related_key] = related
        new_owner = new Owner(attributes)
        owner1 = null; new_owner1 = null; new_owner_id = null

        assert.equal(related, owner.get(related_key), "Didn't modify previous related. Expected: #{related}. Actual: #{owner.get(related_key)}")
        assert.equal(related_id, owner.get(related_id_accessor), "Got related_id from previous related. Expected: #{related_id}. Actual: #{owner.get(related_id_accessor)}")
        assert.equal(related, new_owner.get(related_key), "Copied related. Expected: #{related}. Actual: #{new_owner.get(related_key)}")
        assert.equal(related_id, new_owner.get(related_id_accessor), "Got related_id from copied related. Expected: #{related_id}. Actual: #{new_owner.get(related_id_accessor)}")

        queue = new Queue(1)
        queue.defer (callback) -> new_owner.save callback
        queue.defer (callback) -> owner.save callback

        # make sure nothing changed after save
        queue.defer (callback) ->
          new_owner_id = new_owner.id
          assert.ok(new_owner_id, 'had an id after after')

          assert.equal(related, owner.get(related_key), "Didn't modify previous related. Expected: #{related}. Actual: #{owner.get(related_key)}")
          assert.equal(related_id, owner.get(related_id_accessor), "Got related_id from previous related. Expected: #{related_id}. Actual: #{owner.get(related_id_accessor)}")
          assert.equal(related, new_owner.get(related_key), "Copied related. Expected: #{related}. Actual: #{new_owner.get(related_key)}")
          assert.equal(related_id, new_owner.get(related_id_accessor), "Got related_id from copied related. Expected: #{related_id}. Actual: #{new_owner.get(related_id_accessor)}")
          callback()

        # load
        queue.defer (callback) -> Owner.find owner_id, (err, _owner) -> callback(err, owner1 = _owner)
        queue.defer (callback) -> Owner.find new_owner_id, (err, _owner) -> callback(err, new_owner1 = _owner)

        # check
        queue.defer (callback) ->
          assert.equal(related_id, owner1.get(related_id_accessor), "Got related_id from reloaded previous related. Expected: #{related_id}. Actual: #{owner1.get(related_id_accessor)}")
          assert.equal(related_id, new_owner1.get(related_id_accessor), "Got related_id from reloaded copied related. Expected: #{related_id}. Actual: #{new_owner1.get(related_id_accessor)}")

          owner1.get related_key, (err, related) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(related_id, related.id, "Loaded related from previous related. Expected: #{related_id}. Actual: #{related.id}")

            new_owner1.get related_key, (err, related) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(related_id, related.id, "Loaded related from previous related. Expected: #{related_id}. Actual: #{related.id}")
              callback()

        queue.await done

    it 'Can create a model and update the relationship (hasOne)', (done) ->
      # TODO: implement embedded set - should clone in set or the caller needed to clone? (problem is sharing an in memory instance)
      return done() if options.embed

      related_key = 'reverse'
      related_id_accessor = 'reverse_id'

      Owner.cursor().include(related_key).toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        related = owner.get(related_key)
        owner_id = owner.id
        related_id = related.id
        assert.ok(related, 'included related')

        (attributes = {})[related_key] = related
        new_owner = new Owner(attributes)
        owner1 = null; new_owner1 = null; new_owner_id = null

        assert.equal(null, owner.get(related_key), "Modified previous related. Expected: #{null}. Actual: #{owner.get(related_key)}")
        assert.equal(null, owner.get(related_id_accessor), "Failed to get related_id from previous related. Expected: #{null}. Actual: #{new_owner.get(related_id_accessor)}")
        assert.equal(related, new_owner.get(related_key), "Copied related. Expected: #{related}. Actual: #{new_owner.get(related_key)}")
        assert.equal(related_id, new_owner.get(related_id_accessor), "Got related_id from copied related. Expected: #{related_id}. Actual: #{new_owner.get(related_id_accessor)}")

        queue = new Queue(1)
        queue.defer (callback) -> new_owner.save callback
        queue.defer (callback) -> owner.save callback

        # make sure nothing changed after save
        queue.defer (callback) ->
          new_owner_id = new_owner.id
          assert.ok(new_owner_id, 'had an id after after')

          assert.equal(null, owner.get(related_key), "Modified previous related. Expected: #{null}. Actual: #{owner.get(related_key)}")
          assert.equal(null, owner.get(related_id_accessor), "Got related_id from previous related. Expected: #{null}. Actual: #{new_owner.get(related_id_accessor)}")
          assert.equal(related, new_owner.get(related_key), "Copied related. Expected: #{related}. Actual: #{new_owner.get(related_key)}")
          assert.equal(related_id, new_owner.get(related_id_accessor), "Got related_id from copied related. Expected: #{related_id}. Actual: #{new_owner.get(related_id_accessor)}")
          callback()

        # load
        queue.defer (callback) -> Owner.find owner_id, (err, _owner) -> callback(err, owner1 = _owner)
        queue.defer (callback) -> Owner.find new_owner_id, (err, _owner) -> callback(err, new_owner1 = _owner)

        # check
        queue.defer (callback) ->
          owner1.get related_key, (err, related) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(null, related, "Failed to loaded related from previous related. Expected: #{null}. Actual: #{related}")
            assert.equal(null, owner1.get(related_id_accessor), "Failed to get related_id from reloaded previous related. Expected: #{null}. Actual: #{owner1.get(related_id_accessor)}")

            new_owner1.get related_key, (err, related) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(related_id, related.id, "Loaded related from previous related. Expected: #{related_id}. Actual: #{related.id}")
              assert.equal(related_id, new_owner1.get(related_id_accessor), "Got related_id from reloaded copied related. Expected: #{related_id}. Actual: #{new_owner1.get(related_id_accessor)}")
              callback()

        queue.await done

    # TODO: should the related model be loaded to save?
    it.skip 'Can create a related model by id (hasOne)', (done) ->
      Reverse.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        reverse_id = test_model.id
        new_model = new Owner()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({reverse_id: reverse_id})
          new_model.save (err) ->
            assert.ok(!err, "No errors: #{err}")

            new_model.get 'reverse', (err, reverse) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(reverse, 'found related model')
              assert.equal(reverse_id, reverse.id, 'Loaded model is correct')
              done()

    it 'Handles a get query for a belongsTo relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'flat', (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(flat, 'found related model')
          if test_model.relationIsEmbedded('flat')
            assert.deepEqual(test_model.toJSON().flat, flat.toJSON(), "Serialized embed. Expected: #{JSONUtils.stringify(test_model.toJSON().flat)}. Actual: #{JSONUtils.stringify(flat.toJSON())}")
          else
            assert.deepEqual(test_model.toJSON().flat_id, flat.id, "Serialized id only. Expected: #{test_model.toJSON().flat_id}. Actual: #{flat.id}")
          assert.equal(test_model.get('flat_id'), flat.id, "\nExpected: #{test_model.get('flat_id')}\nActual: #{flat.id}")
          done()

    it 'Handles a get query for a hasOne relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'reverse', (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found related model')
          assert.equal(test_model.id, reverse.get('owner_id'), "\nExpected: #{test_model.id}\nActual: #{reverse.get('owner_id')}")
          assert.equal(test_model.id, reverse.toJSON().owner_id, "\nReverse toJSON has an owner_id. Expected: #{test_model.id}\nActual: #{reverse.toJSON().owner_id}")
          if test_model.relationIsEmbedded('reverse')
            assert.deepEqual(test_model.toJSON().reverse, reverse.toJSON(), "Serialized embed. Expected: #{JSONUtils.stringify(test_model.toJSON().reverse)}. Actual: #{JSONUtils.stringify(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_id, 'No reverese_id in owner json')
          done()

    it 'Can retrieve an id for a hasOne relation via async virtual method', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        test_model.get 'reverse_id', (err, id) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(id, 'found id')
          done()

    it 'Can retrieve a belongsTo id synchronously and then a model asynchronously from get methods', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        assert.ok(test_model.get('flat_id'), 'Has the belongsTo id')
        test_model.get 'flat', (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(flat, 'loaded model')
          assert.equal(test_model.get('flat_id'), flat.id, "\nExpected: #{test_model.get('flat_id')}\nActual: #{flat.id}")
          done()

    it 'Handles a get query for a hasOne and belongsTo two sided relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'reverse', (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found related model')
          assert.equal(test_model.id, reverse.get('owner_id'), "\nExpected: #{test_model.id}\nActual: #{reverse.get('owner_id')}")
          assert.equal(test_model.id, reverse.toJSON().owner_id, "\nReverse toJSON has an owner_id. Expected: #{test_model.id}\nActual: #{reverse.toJSON().owner_id}")
          if test_model.relationIsEmbedded('reverse')
            assert.deepEqual(test_model.toJSON().reverse, reverse.toJSON(), "Serialized embed. Expected: #{JSONUtils.stringify(test_model.toJSON().reverse)}. Actual: #{JSONUtils.stringify(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_id, 'No reverse_id in owner json')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'found original model')
            assert.deepEqual(reverse.toJSON().owner_id, owner.id, "Serialized id only. Expected: #{reverse.toJSON().owner_id}. Actual: #{owner.id}")

            if Owner.cache
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "\nExpected: #{JSONUtils.stringify(test_model.toJSON())}\nActual: #{JSONUtils.stringify(owner.toJSON())}")
            else
              assert.equal(test_model.id, owner.id, "\nExpected: #{test_model.id}\nActual: #{owner.id}")
            done()

    it 'Appends json for a related model', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        JSONUtils.renderRelated test_model, 'reverse', ['id', 'created_at'], (err, related_json) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(related_json.id, "reverse has an id")
          assert.ok(related_json.created_at, "reverse has a created_at")
          assert.ok(!related_json.updated_at, "reverse doesn't have updated_at")

          JSONUtils.renderRelated test_model, 'flat', ['id', 'created_at'], (err, related_json) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(related_json.id, "flat has an id")
#            assert.ok(related_json.created_at, "flat has a created_at")
            assert.ok(!related_json.updated_at, "flat doesn't have updated_at")
            done()

    # TODO: delay the returning of memory models related models to test lazy loading properly
    it 'Fetches a relation from the store if not present', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        fetched_owner = new Owner({id: test_model.id})
        fetched_owner.fetch (err) ->
          assert.ok(!err, "No errors: #{err}")
          delete fetched_owner.attributes.reverse

          fetched_owner.get 'reverse', (err, reverse) ->
            if fetched_owner.relationIsEmbedded('reverse')
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!reverse, 'Cannot yet load the model') # TODO: implement a fetch from the related model
              done()
            else
              assert.ok(!err, "No errors: #{err}")
              assert.ok(reverse, 'loaded the model lazily')
              assert.equal(reverse.get('owner_id'), test_model.id)
              done()
    #          assert.equal(reverse, null, 'has not loaded the model initially')

    it 'Has an id loaded for a belongsTo and not for a hasOne relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        assert.ok(test_model.get('flat_id'), 'belongsTo id is loaded')
        #        assert.ok(!test_model.get('reverse_id'), 'hasOne id is not loaded')
        done()

    it 'Handles a get query for a hasOne and belongsTo two sided relation as "as" fields', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'reverse_as', (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found related model')
          assert.equal(test_model.id, reverse.get('owner_as_id'), "\nExpected: #{test_model.id}\nActual: #{reverse.get('owner_as_id')}")
          assert.equal(test_model.id, reverse.toJSON().owner_as_id, "\nReverse toJSON has an owner_id. Expected: #{test_model.id}\nActual: #{reverse.toJSON().owner_as_id}")
          if test_model.relationIsEmbedded('reverse_as')
            assert.deepEqual(test_model.toJSON().reverse_as, reverse.toJSON(), "Serialized embed. Expected: #{JSONUtils.stringify(test_model.toJSON().reverse)}. Actual: #{JSONUtils.stringify(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_as_id, 'No reverse_as_id in owner json')

          reverse.get 'owner_as', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'found original model')
            assert.deepEqual(reverse.toJSON().owner_as_id, owner.id, "Serialized id only. Expected: #{reverse.toJSON().owner_as_id}. Actual: #{owner.id}")

            if Owner.cache
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "\nExpected: #{JSONUtils.stringify(test_model.toJSON())}\nActual: #{JSONUtils.stringify(owner.toJSON())}")
            else
              assert.equal(test_model.id, owner.id, "\nExpected: #{test_model.id}\nActual: #{owner.id}")
            done()

    it 'Can include a related (belongsTo) model', (done) ->
      Owner.cursor({$one: true}).include('flat').toJSON (err, json) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(json, 'found model')
        assert.ok(json.flat, "Has a related flat")
        assert.ok(json.flat.id, "Related model has an id")

        unless Owner.relationIsEmbedded('flat') # TODO: confirm this is correct
          assert.equal(json.flat_id, json.flat.id, "\nRelated model has the correct id: Expected: #{json.flat_id}\nActual: #{json.flat.id}")
        done()

    it 'Can include a related (hasOne) model', (done) ->
      Owner.cursor({$one: true}).include('reverse').toJSON (err, json) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(json, 'found model')
        assert.ok(json.reverse, "Has a related reverse")
        assert.ok(json.reverse.id, "Related model has an id")
        assert.equal(json.id, json.reverse.owner_id, "\nRelated model has the correct id: Expected: #{json.id}\nActual: #{json.reverse.owner_id}")
        done()

    it 'Can include multiple related models', (done) ->
      Owner.cursor({$one: true}).include('reverse', 'flat').toJSON (err, json) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(json, 'found model')
        assert.ok(json.reverse, "Has a related reverse")
        assert.ok(json.reverse.id, "Related model has an id")
        assert.ok(json.flat, "Has a related flat")
        assert.ok(json.flat.id, "Included model has an id")

        unless Owner.relationIsEmbedded('flat') # TODO: confirm this is correct
          assert.equal(json.flat_id, json.flat.id, "\nIncluded model has the correct id: Expected: #{json.flat_id}\nActual: #{json.flat.id}")
        assert.equal(json.id, json.reverse.owner_id, "\nIncluded model has the correct id: Expected: #{json.id}\nActual: #{json.reverse.owner_id}")
        done()

    it 'Can query on a related (belongsTo) model property', (done) ->
      Flat.findOne (err, flat) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(flat, 'found model')

        Owner.cursor({$one: true, 'flat.id': flat.id}).toJSON (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found model')
          unless Owner.relationIsEmbedded('flat') # TODO: confirm this is correct
            assert.equal(flat.id, owner.flat_id, "\nRelated model has the correct id: Expected: #{flat.id}\nActual: #{owner.flat_id}")
          done()

    it 'Can query on a related (belongsTo) model property when the relation is included', (done) ->
      Flat.findOne (err, flat) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(flat, 'found model')
        Owner.cursor({$one: true, 'flat.name': flat.get('name')}).include('flat').toJSON (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found model')
          assert.ok(owner.flat, "Has a related flat")
          assert.ok(owner.flat.id, "Included model has an id")
          assert.equal(flat.id, owner.flat.id, "\nIncluded model has the correct id: Expected: #{flat.id}\nActual: #{owner.flat.id}")
          assert.equal(flat.get('name'), owner.flat.name, "\nIncluded model has the correct name: Expected: #{flat.get('name')}\nActual: #{owner.flat.name}")
          done()

    it 'Can query on a related (hasOne) model', (done) ->
      Reverse.findOne (err, reverse) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(reverse, 'Reverse found model')
        Owner.cursor({$one: true, 'reverse.name': reverse.get('name')}).toJSON (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'Owner found model')

          unless Owner.relationIsEmbedded('reverse') # TODO: confirm this is correct
            assert.equal(reverse.get('owner_id'), owner.id, "\nRelated model has the correct id: Expected: #{reverse.get('owner_id')}\nActual: #{owner.id}")
          done()

    it 'Can query on a related (hasOne) model property when the relation is included', (done) ->
      Reverse.findOne (err, reverse) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(reverse, 'found model')
        Owner.cursor({'reverse.name': reverse.get('name')}).include('reverse').toJSON (err, json) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(json, "found json")
          assert.equal(json.length, 1, "json has the correct number or results. Expecting: 1. Actual #{json.length}")
          owner = json[0]
          assert.ok(owner.reverse, "Has a related reverse")
          assert.ok(owner.reverse.id, "Related model has an id")

          unless Owner.relationIsEmbedded('reverse') # TODO: confirm this is correct
            assert.equal(reverse.get('owner_id'), owner.id, "\nRelated model has the correct id: Expected: #{reverse.get('owner_id')}\nActual: #{owner.id}")
          assert.equal(reverse.get('name'), owner.reverse.name, "\nIncluded model has the correct name: Expected: #{reverse.get('name')}\nActual: #{owner.reverse.name}")
          done()

    it 'Should be able to count relationships', (done) ->
      # TODO: implement embedded find
      return done() if options.embed

      Owner.findOne (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')

        Reverse.count {owner_id: owner.id}, (err, count) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(1, count, "Counted reverses. Expected: 1. Actual: #{count}")
          done()

    it 'Should be able to count relationships with paging', (done) ->
      # TODO: implement embedded find
      return done() if options.embed

      Owner.findOne (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')

        Reverse.cursor({owner_id: owner.id, $page: true}).toJSON (err, paging_info) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(0, paging_info.offset, "Has offset. Expected: 0. Actual: #{paging_info.offset}")
          assert.equal(1, paging_info.total_rows, "Counted reverses. Expected: 1. Actual: #{paging_info.total_rows}")
          done()

    backlinkTests = (virtual) ->
      it "Should update backlinks using set (#{if virtual then 'virtual' else 'no modifiers'})", (done) ->
        # TODO: implement embedded
        return done() if options.embed

        checkReverseFn = (reverse, expected_owner) -> return (callback) ->
          assert.ok(reverse, 'Reverse exists')
          assert.equal(expected_owner, reverse.get('owner'), "Reverse owner is correct. Expected: #{expected_owner}. Actual: #{reverse.get('owner')}")
          callback()

        Owner.cursor().limit(2).include('reverse').toModels (err, owners) ->
          if virtual # set as virtual relationship after including reverse
            relation = Owner.relation('reverse')
            relation.virtual = true

          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, owners.length, "Found owners. Expected: 2. Actual: #{owners.length}")

          owner0 = owners[0]; owner0_id = owner0.id; reverse0 = owner0.get('reverse')
          owner1 = owners[1]; owner1_id = owner1.id; reverse1 = owner1.get('reverse')

          assert.ok(owner0.get('reverse'), "Owner0 has 1 reverse.")
          assert.ok(owner1.get('reverse'), "Owner1 has 1 reverse.")

          queue = new Queue(1)
          queue.defer checkReverseFn(reverse0, owner0)
          queue.defer checkReverseFn(reverse1, owner1)
          queue.defer (callback) ->
            owner0.set({reverse: reverse1})

            assert.ok(owner0.get('reverse'), "Owner0 has 1 reverse.")
            assert.ok(!owner1.get('reverse'), "Owner1 has no reverse.")

            queue.defer checkReverseFn(reverse1, owner0) # confirm it also is related
            queue.defer checkReverseFn(reverse0, owner0) # confirm it stayed
            assert.equal(null, owner1.get('reverse'), "Owner's reverse is cleared.\nExpected: #{null}.\nActual: #{JSONUtils.stringify(owner1.get('reverse'))}")
            callback()

          # save and recheck
          queue.defer (callback) -> owner0.save callback
          queue.defer (callback) -> owner1.save callback
          queue.defer (callback) ->
            BackboneORM.model_cache.reset() # reset cache
            Owner.cursor({$ids: [owner0.id, owner1.id]}).limit(2).include('reverse').toModels (err, owners) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(2, owners.length, "Found owners post-save. Expected: 2. Actual: #{owners.length}")

              # lookup owners
              owner0 = owner1 = null
              for owner in owners
                if owner.id is owner0_id
                  owner0 = owner
                else if owner.id is owner1_id
                  owner1 = owner
              assert(owner0, 'refound owner0')
              assert(owner1, 'refound owner1')
              reverse0b = owner0.get('reverse')
              reverse1b = owner1.get('reverse')

              if virtual
                assert.ok(owner0.get('reverse'), "Owner0 has 1 reverse.")
                assert.ok(owner1.get('reverse'), "Owner1 has 1 reverse.")
              else
                assert.ok(owner0.get('reverse'), "Owner0 has 1 reverse.")
                assert.ok(!owner1.get('reverse'), "Owner1 has no reverse.")

                queue.defer checkReverseFn(reverse0b, owner0) # confirm it moved

                # TODO: determine reason on SQL for updated_at missing
                # assert.deepEqual(reverse1.toJSON(), reverse0b.toJSON(), "Reverse is cleared.\nExpected: #{JSONUtils.stringify(reverse1.toJSON())}.\nActual: #{JSONUtils.stringify(reverse0b.toJSON())}")
                assert.deepEqual(_.pick(reverse1.toJSON(), 'created_at'), _.pick(reverse0b.toJSON(), 'created_at'), "Reverse is cleared.\nExpected: #{JSONUtils.stringify(_.pick(reverse1.toJSON(), 'updated_at', 'created_at'))}.\nActual: #{JSONUtils.stringify(_.pick(reverse0b.toJSON(), 'updated_at', 'created_at'))}")

                assert.equal(null, owner1.get('reverse'), "Owner's reverse is cleared.\nExpected: #{null}.\nActual: #{JSONUtils.stringify(owner1.get('reverse'))}")
              callback()

          queue.await (err) ->
            assert.ok(!err, "No errors: #{err}")
            done()

    backlinkTests(false)
    backlinkTests(true)

    it 'does not serialize virtual attributes', (done) ->
      json_key = if options.embed then 'flat' else 'flat_id'

      Owner.findOne (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'Owners found')
        flat_id = owner.get('flat').id

        json = owner.toJSON()
        assert.ok(json.hasOwnProperty(json_key), 'Serialized flat')

        relation = owner.relation('flat')
        relation.virtual = true

        virtual_json = owner.toJSON()
        assert.ok(!virtual_json.hasOwnProperty(json_key), 'Did not serialize flat')

        owner_with_flat = new Owner(json)
        assert.equal(owner_with_flat.get('flat').id, flat_id, 'Virtual with flat was deserialized')

        owner_with_virtual_flat = new Owner(virtual_json)
        assert.equal(owner_with_virtual_flat.get('flat'), null, 'Virtual without flat was deserialized')
        done()

        # owner.save {flat: null}, (err) ->
        #   assert.ok(!err, "No errors: #{err}")

        #   BackboneORM.model_cache.reset() # reset cache
        #   Owner.find owner.id, (err, loaded_owner) ->
        #     assert.ok(!err, "No errors: #{err}")
        #     assert.equal(loaded_owner.get('flat').id, flat_id, 'Virtual flat is not saved')
        #     done()
