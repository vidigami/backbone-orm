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

  describe "hasMany #{options.$parameter_tags or ''}#{options.$tags}", ->
    Flat = Reverse = ForeignReverse = Owner = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

      class Reverse extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/reverses"
        schema: _.defaults({
          owner: -> ['belongsTo', Owner]
          another_owner: -> ['belongsTo', Owner, as: 'more_reverses']
        }, BASE_SCHEMA)
        sync: SYNC(Reverse)

      class ForeignReverse extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/foreign_reverses"
        schema: _.defaults({
          owner: -> ['belongsTo', Owner, foreign_key: 'ownerish_id']
        }, BASE_SCHEMA)
        sync: SYNC(ForeignReverse)

      class Owner extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/owners"
        schema: _.defaults({
          flats: -> ['hasMany', Flat]
          reverses: -> ['hasMany', Reverse]
          more_reverses: -> ['hasMany', Reverse, as: 'another_owner']
          foreign_reverses: -> ['hasMany', ForeignReverse]
        }, BASE_SCHEMA)
        sync: SYNC(Owner)

    after (callback) -> Utils.resetSchemas [Flat, Reverse, ForeignReverse, Owner], callback

    beforeEach (callback) ->
      relation = Owner.relation('reverses')
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
        save_queue = new Queue()

        link_tasks = []
        for owner in MODELS.owner
          link_task =
            owner: owner
            values:
              flats: [MODELS.flat.pop(), MODELS.flat.pop()]
              reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]
              more_reverses: [MODELS.more_reverse.pop(), MODELS.more_reverse.pop()]
              foreign_reverses: [MODELS.foreign_reverse.pop()]
          link_tasks.push(link_task)

        for link_task in link_tasks then do (link_task) -> save_queue.defer (callback) ->
          link_task.owner.set(link_task.values)
          link_task.owner.save callback

        save_queue.await callback

      queue.await callback

    it 'Can fetch and serialize a custom foreign key', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'foreign_reverses', (err, related_models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(1, related_models.length, "found related models. Expected: #{1}. Actual: #{related_models.length}")

          for related_model in related_models
            related_json = related_model.toJSON()
            assert.equal(test_model.id, related_json.ownerish_id, "Serialized the foreign id. Expected: #{test_model.id}. Actual: #{related_json.ownerish_id}")
          done()

    # TODO: should related models be loaded to save?
    it.skip 'Can create a model and load a related model by id (hasMany)', (done) ->
      Reverse.cursor({$values: 'id'}).limit(4).toJSON (err, reverse_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, reverse_ids.length, "found 4 reverses. Actual: #{reverse_ids.length}")

        new_model = new Owner()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({reverses: reverse_ids})
          new_model.get 'reverses', (err, reverses) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(4, reverses.length, "found 4 related model. Actual: #{reverses.length}")
            assert.equal(_.difference(reverse_ids, (test.id for test in reverses)).length, 0, "expected owners: #{_.difference(reverse_ids, (test.id for test in reverses))}")
            done()

    # TODO: should related models be loaded to save?
    it.skip 'Can create a model and load a related model by id (hasMany)', (done) ->
      Reverse.cursor({$values: 'id'}).limit(4).toJSON (err, reverse_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, reverse_ids.length, "found 4 reverses. Actual: #{reverse_ids.length}")

        new_model = new Owner()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({reverse_ids: reverse_ids})
          new_model.get 'reverses', (err, reverses) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(4, reverses.length, "found 4 related model. Actual: #{reverses.length}")
            assert.equal(_.difference(reverse_ids, (test.id for test in reverses)).length, 0, "expected owners: #{_.difference(reverse_ids, (test.id for test in reverses))}")
            done()

    # TODO: should related models be loaded to save?
    it.skip 'Can create a model and load a related model by id (belongsTo)', (done) ->
      Owner.cursor({$values: 'id'}).limit(4).toJSON (err, owner_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, owner_ids.length, "found 4 owners. Actual: #{owner_ids.length}")

        new_model = new Reverse()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({owner: owner_ids[0]})
          new_model.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'loaded a model')
            assert.equal(owner_ids[0], owner.id, "loaded correct model. Expected: #{owner_ids[0]}. Actual: #{owner.id}")
            done()

    # TODO: should related models be loaded to save?
    it.skip 'Can create a model and load a related model by id (belongsTo)', (done) ->
      Owner.cursor({$values: 'id'}).limit(4).toJSON (err, owner_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, owner_ids.length, "found 4 owners. Actual: #{owner_ids.length}")

        new_model = new Reverse()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({owner_id: owner_ids[0]})
          new_model.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'loaded a model')
            assert.equal(owner_ids[0], owner.id, "loaded correct model. Expected: #{owner_ids[0]}. Actual: #{owner.id}")
            done()

    patchAddTests = (unload) ->
      it "Can manually add a relationship by related_id (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.cursor().include('reverses').toModel (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')
          reverses = owner.get('reverses').models
          assert.equal(reverses.length, 2, "loaded correct models. Expected: #{2}. Actual: #{reverses.length}.")
          reverse_ids = (reverse.id for reverse in reverses)

          Owner.cursor({id: {$ne: owner.id}}).include('reverses').toModel (err, another_owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(another_owner, "loaded another model.")
            assert.ok(owner.id isnt another_owner.id, "loaded a model with a different id.")

            another_reverses = another_owner.get('reverses').models
            assert.equal(another_reverses.length, 2, "loaded correct models. Expected: #{2}. Actual: #{another_reverses.length}.")
            another_reverse_ids = (reverse.id for reverse in another_reverses)
            moved_reverse_id = another_reverse_ids[0]
            moved_reverse_json = another_reverses[0].toJSON()

            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchAdd 'reverses', moved_reverse_id, (err) ->
              assert.ok(!err, "No errors: #{err}")

              owner.get 'reverses', (err) ->
                assert.ok(!err, "No errors: #{err}")

                updated_reverses = owner.get('reverses').models
                updated_reverse_ids = (reverse.id for reverse in updated_reverses)

                assert.equal(updated_reverse_ids.length, 3, "Moved the reverse. Expected: #{3}. Actual: #{updated_reverse_ids.length}")
                assert.ok(_.contains(updated_reverse_ids, moved_reverse_id), "Moved the reverse_id")

                Owner.cursor({id: another_owner.id}).include('reverses').toModel (err, another_owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  updated_another_reverses = another_owner.get('reverses').models
                  updated_another_reverse_ids = (reverse.id for reverse in updated_another_reverses)
                  assert.equal(updated_another_reverse_ids.length, 1, "Moved the reverse from previous. Expected: #{1}. Actual: #{updated_another_reverse_ids.length}")
                  assert.ok(!_.contains(updated_another_reverse_ids, moved_reverse_id), "Moved the reverse_id from previous")

                  owner.get 'reverses', (err, updated_reverses) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.equal(updated_reverses.length, 3, "loaded correct models. Expected: #{3}. Actual: #{updated_reverses.length}.")
                    updated_reverse_ids = (reverse.id for reverse in updated_reverses)

                    assert.equal(updated_reverse_ids.length, 3, "Moved the reverse. Expected: #{3}. Actual: #{updated_reverse_ids.length}")
                    assert.ok(_.contains(updated_reverse_ids, moved_reverse_id), "Moved the reverse_id")
                    updated_moved_reverse = updated_reverses[_.indexOf(updated_reverse_ids, moved_reverse_id)]

                    assert.ok(_.isEqual(_.pick(updated_moved_reverse.toJSON(), PICK_KEYS), _.pick(moved_reverse_json, PICK_KEYS)), "Set the id:. Expected: #{JSONUtils.stringify(_.pick(updated_moved_reverse.toJSON(), PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(moved_reverse_json, PICK_KEYS))}")
                    done()

      it "Can manually add a relationship by related json (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.cursor().include('reverses').toModel (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')
          reverses = owner.get('reverses').models
          assert.equal(reverses.length, 2, "loaded correct models. Expected: #{2}. Actual: #{reverses.length}.")
          reverse_ids = (reverse.id for reverse in reverses)

          Owner.cursor({id: {$ne: owner.id}}).include('reverses').toModel (err, another_owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(another_owner, "loaded another model.")
            assert.ok(owner.id isnt another_owner.id, "loaded a model with a different id.")

            another_reverses = another_owner.get('reverses').models
            assert.equal(another_reverses.length, 2, "loaded correct models. Expected: #{2}. Actual: #{another_reverses.length}.")
            another_reverse_ids = (reverse.id for reverse in another_reverses)
            moved_reverse_id = another_reverse_ids[0]
            moved_reverse_json = another_reverses[0].toJSON()

            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchAdd 'reverses', moved_reverse_json, (err) ->
              assert.ok(!err, "No errors: #{err}")
              owner.get 'reverses', (err) ->
                assert.ok(!err, "No errors: #{err}")
                updated_reverses = owner.get('reverses').models
                updated_reverse_ids = (reverse.id for reverse in updated_reverses)

                assert.equal(updated_reverse_ids.length, 3, "Moved the reverse. Expected: #{3}. Actual: #{updated_reverse_ids.length}")
                assert.ok(_.contains(updated_reverse_ids, moved_reverse_id), "Moved the reverse_id")

                Owner.cursor({id: another_owner.id}).include('reverses').toModel (err, another_owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  updated_another_reverses = another_owner.get('reverses').models
                  updated_another_reverse_ids = (reverse.id for reverse in updated_another_reverses)
                  assert.equal(updated_another_reverse_ids.length, 1, "Moved the reverse from previous. Expected: #{1}. Actual: #{updated_another_reverse_ids.length}")
                  assert.ok(!_.contains(updated_another_reverse_ids, moved_reverse_id), "Moved the reverse_id from previous")

                  owner.get 'reverses', (err, updated_reverses) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.equal(updated_reverses.length, 3, "loaded correct models. Expected: #{3}. Actual: #{updated_reverses.length}")
                    updated_reverse_ids = (reverse.id for reverse in updated_reverses)

                    assert.equal(updated_reverse_ids.length, 3, "Moved the reverse. Expected: #{3}. Actual: #{updated_reverse_ids.length}")
                    assert.ok(_.contains(updated_reverse_ids, moved_reverse_id), "Moved the reverse_id")
                    updated_moved_reverse = updated_reverses[_.indexOf(updated_reverse_ids, moved_reverse_id)]

                    assert.ok(_.isEqual(_.pick(updated_moved_reverse.toJSON(), PICK_KEYS), _.pick(moved_reverse_json, PICK_KEYS)), "Set the id:. Expected: #{JSONUtils.stringify(_.pick(updated_moved_reverse.toJSON(), PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(moved_reverse_json, PICK_KEYS))}")
                    done()

      it "Can manually add a relationship by related model (hasOne)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Owner.cursor().include('reverses').toModel (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')
          reverses = owner.get('reverses').models
          assert.equal(reverses.length, 2, "loaded correct models. Expected: #{2}. Actual: #{reverses.length}.")
          reverse_ids = (reverse.id for reverse in reverses)

          Owner.cursor({id: {$ne: owner.id}}).include('reverses').toModel (err, another_owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(another_owner, "loaded another model.")
            assert.ok(owner.id isnt another_owner.id, "loaded a model with a different id.")

            another_reverses = another_owner.get('reverses').models
            assert.equal(another_reverses.length, 2, "loaded correct models. Expected: #{2}. Actual: #{another_reverses.length}.")
            another_reverse_ids = (reverse.id for reverse in another_reverses)
            moved_reverse_id = another_reverse_ids[0]
            moved_reverse_json = another_reverses[0].toJSON()

            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchAdd 'reverses', another_reverses[0], (err) ->
              assert.ok(!err, "No errors: #{err}")
              owner.get 'reverses', (err) ->
                assert.ok(!err, "No errors: #{err}")
                updated_reverses = owner.get('reverses').models
                updated_reverse_ids = (reverse.id for reverse in updated_reverses)

                assert.equal(updated_reverse_ids.length, 3, "Moved the reverse. Expected: #{3}. Actual: #{updated_reverse_ids.length}")
                assert.ok(_.contains(updated_reverse_ids, moved_reverse_id), "Moved the reverse_id")

                Owner.cursor({id: another_owner.id}).include('reverses').toModel (err, another_owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  updated_another_reverses = another_owner.get('reverses').models
                  updated_another_reverse_ids = (reverse.id for reverse in updated_another_reverses)
                  assert.equal(updated_another_reverse_ids.length, 1, "Moved the reverse from previous. Expected: #{1}. Actual: #{updated_another_reverse_ids.length}")
                  assert.ok(!_.contains(updated_another_reverse_ids, moved_reverse_id), "Moved the reverse_id from previous")

                  owner.get 'reverses', (err, updated_reverses) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.equal(updated_reverses.length, 3, "loaded correct models. Expected: #{3}. Actual: #{updated_reverses.length}")
                    updated_reverse_ids = (reverse.id for reverse in updated_reverses)

                    assert.equal(updated_reverse_ids.length, 3, "moved the reverse. Expected: #{3}. Actual: #{updated_reverses.length}")
                    assert.ok(_.contains(updated_reverse_ids, moved_reverse_id), "Moved the reverse_id")
                    updated_moved_reverse = updated_reverses[_.indexOf(updated_reverse_ids, moved_reverse_id)]

                    assert.ok(_.isEqual(_.pick(updated_moved_reverse.toJSON(), PICK_KEYS), _.pick(moved_reverse_json, PICK_KEYS)), "Set the id:. Expected: #{JSONUtils.stringify(_.pick(updated_moved_reverse.toJSON(), PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(moved_reverse_json, PICK_KEYS))}")
                    done()

      it "Can manually add a relationship by related_id (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne {owner_id: {$ne: null}}, (err, reverse) ->
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
                reverse.get 'owner', (err) ->
                  assert.ok(!err, "No errors: #{err}")
                  updated_owner = reverse.get('owner')
                  assert.ok(updated_owner.id is another_owner_json.id, "Set the id. Expected: #{another_owner_json.id}. Actual: #{updated_owner.id}")

                  reverse.get 'owner', (err, updated_owner) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(updated_owner, "loaded another model.")

                    assert.ok(_.contains(updated_owner.get('reverse_ids'), reverse.id), "reverse_id is correct.")
                    assert.ok(_.isEqual(_.pick(updated_owner.toJSON(), PICK_KEYS), _.pick(another_owner_json, PICK_KEYS)), "Set the id. Expected: #{JSONUtils.stringify(_.pick(another_owner_json, PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(updated_owner.toJSON(), PICK_KEYS))}")
                    done()

      it "Can manually add a relationship by related json (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne {owner_id: {$ne: null}}, (err, reverse) ->
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
                reverse.get 'owner', (err) ->
                  assert.ok(!err, "No errors: #{err}")
                  updated_owner = reverse.get('owner')
                  assert.ok(updated_owner.id is another_owner_json.id, "Set the id. Expected: #{another_owner_json.id}. Actual: #{updated_owner.id}")

                  reverse.get 'owner', (err, updated_owner) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(updated_owner, "loaded another model.")

                    assert.ok(_.contains(updated_owner.get('reverse_ids'), reverse.id), "reverse_id is correct.")
                    assert.ok(_.isEqual(_.pick(updated_owner.toJSON(), PICK_KEYS), _.pick(another_owner_json, PICK_KEYS)), "Set the id. Expected: #{JSONUtils.stringify(_.pick(another_owner_json, PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(updated_owner.toJSON(), PICK_KEYS))}")
                    done()

      it "Can manually add a relationship by related model (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        # TODO: implement embedded find
        return done() if options.embed

        Reverse.findOne {owner_id: {$ne: null}}, (err, reverse) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverse, 'found reverse')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, "loaded correct model.")

            Owner.cursor({id: {$ne: owner.id}}).toModel (err, another_owner) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(another_owner, "loaded another model.")
              assert.ok(owner.id isnt another_owner.id, "loaded a model with a different id.")
              another_owner_json = another_owner.toJSON()

              if unload
                BackboneORM.model_cache.reset() # reset cache
                reverse = new Reverse({id: reverse.id})
              reverse.patchAdd 'owner', another_owner, (err) ->
                assert.ok(!err, "No errors: #{err}")
                reverse.get 'owner', (err) ->
                  assert.ok(!err, "No errors: #{err}")
                  updated_owner = reverse.get('owner')
                  assert.ok(updated_owner.id is another_owner.id, "Set the id. Expected: #{another_owner.id}. Actual: #{updated_owner.id}")

                  reverse.get 'owner', (err, updated_owner) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.ok(updated_owner, "loaded another model.")

                    assert.ok(_.contains(updated_owner.get('reverse_ids'), reverse.id), "reverse_id is correct.")
                    assert.ok(_.isEqual(_.pick(updated_owner.toJSON(), PICK_KEYS), _.pick(another_owner_json, PICK_KEYS)), "Set the id. Expected: #{JSONUtils.stringify(_.pick(another_owner_json, PICK_KEYS))}. Actual: #{JSONUtils.stringify(_.pick(updated_owner.toJSON(), PICK_KEYS))}")
                    done()

    patchAddTests(false)
    patchAddTests(true)

    patchRemoveTests = (unload) ->
      it "Can manually delete a relationship by related_id (hasMany)#{if unload then ' with unloaded model' else ''}", (done) ->
        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverses', (err, reverses) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(2, reverses.length, "loaded correct models. Expected: #{2}. Actual: #{reverses.length}")

            destroyed_model = reverses[0]
            other_model = reverses[1]
            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchRemove 'reverses', destroyed_model.id, (err) ->
              assert.ok(!err, "No errors: #{err}")

              unless unload
                assert.equal(1, owner.get('reverses').models.length, "destroyed in memory relationship. Expected: #{1}. Actual: #{owner.get('reverses').models.length}")
                assert.equal(other_model.id, owner.get('reverses').models[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{owner.get('reverses').models[0].id}")

              owner.get 'reverses', (err, reverses) ->
                assert.ok(!err, "No errors: #{err}")
                assert.equal(1, reverses.length, "loaded correct models. Expected: #{1}. Actual: #{reverses.length}")
                assert.equal(other_model.id, reverses[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{reverses[0].id}")

                Owner.findOne owner.id, (err, owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(owner, 'found owners')

                  owner.get 'reverses', (err, reverses) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.equal(1, reverses.length, "loaded correct models. Expected: #{1}. Actual: #{reverses.length}")
                    assert.equal(other_model.id, reverses[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{reverses[0].id}")
                    done()

      it "Can manually delete a relationship by related_json (hasMany)#{if unload then ' with unloaded model' else ''}", (done) ->
        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverses', (err, reverses) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(2, reverses.length, "loaded correct models. Expected: #{2}. Actual: #{reverses.length}")

            destroyed_model = reverses[0]
            other_model = reverses[1]
            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchRemove 'reverses', destroyed_model.toJSON(), (err) ->
              assert.ok(!err, "No errors: #{err}")

              unless unload
                assert.equal(1, owner.get('reverses').models.length, "destroyed in memory relationship. Expected: #{1}. Actual: #{owner.get('reverses').models.length}")
                assert.equal(other_model.id, owner.get('reverses').models[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{owner.get('reverses').models[0].id}")

              owner.get 'reverses', (err, reverses) ->
                assert.ok(!err, "No errors: #{err}")
                assert.equal(1, reverses.length, "loaded correct models. Expected: #{1}. Actual: #{reverses.length}")
                assert.equal(other_model.id, reverses[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{reverses[0].id}")

                Owner.findOne owner.id, (err, owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(owner, 'found owners')

                  owner.get 'reverses', (err, reverses) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.equal(1, reverses.length, "loaded correct models. Expected: #{1}. Actual: #{reverses.length}")
                    assert.equal(other_model.id, reverses[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{reverses[0].id}")
                    done()

      it "Can manually delete a relationship by related_model (hasMany)#{if unload then ' with unloaded model' else ''}", (done) ->
        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverses', (err, reverses) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(2, reverses.length, "loaded correct models. Expected: #{2}. Actual: #{reverses.length}")

            destroyed_model = reverses[0]
            other_model = reverses[1]
            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchRemove 'reverses', destroyed_model, (err) ->
              assert.ok(!err, "No errors: #{err}")

              unless unload
                assert.equal(1, owner.get('reverses').models.length, "destroyed in memory relationship. Expected: #{1}. Actual: #{owner.get('reverses').models.length}")
                assert.equal(other_model.id, owner.get('reverses').models[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{owner.get('reverses').models[0].id}")

              owner.get 'reverses', (err, reverses) ->
                assert.ok(!err, "No errors: #{err}")
                assert.equal(1, reverses.length, "loaded correct models. Expected: #{1}. Actual: #{reverses.length}")
                assert.equal(other_model.id, reverses[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{reverses[0].id}")

                Owner.findOne owner.id, (err, owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(owner, 'found owners')

                  owner.get 'reverses', (err, reverses) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.equal(1, reverses.length, "loaded correct models. Expected: #{1}. Actual: #{reverses.length}")
                    assert.equal(other_model.id, reverses[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{reverses[0].id}")
                    done()

      it "Can manually delete a relationship by array of related_model (hasMany)#{if unload then ' with unloaded model' else ''}", (done) ->
        Owner.findOne (err, owner) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(owner, 'found owners')

          owner.get 'reverses', (err, reverses) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(2, reverses.length, "loaded correct models. Expected: #{2}. Actual: #{reverses.length}")

            destroyed_model = reverses[0]
            other_model = reverses[1]
            if unload
              BackboneORM.model_cache.reset() # reset cache
              owner = new Owner({id: owner.id})
            owner.patchRemove 'reverses', [destroyed_model], (err) ->
              assert.ok(!err, "No errors: #{err}")

              unless unload
                assert.equal(1, owner.get('reverses').models.length, "destroyed in memory relationship. Expected: #{1}. Actual: #{owner.get('reverses').models.length}")
                assert.equal(other_model.id, owner.get('reverses').models[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{owner.get('reverses').models[0].id}")

              owner.get 'reverses', (err, reverses) ->
                assert.ok(!err, "No errors: #{err}")
                assert.equal(1, reverses.length, "loaded correct models. Expected: #{1}. Actual: #{reverses.length}")
                assert.equal(other_model.id, reverses[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{reverses[0].id}")

                Owner.findOne owner.id, (err, owner) ->
                  assert.ok(!err, "No errors: #{err}")
                  assert.ok(owner, 'found owners')

                  owner.get 'reverses', (err, reverses) ->
                    assert.ok(!err, "No errors: #{err}")
                    assert.equal(1, reverses.length, "loaded correct models. Expected: #{1}. Actual: #{reverses.length}")
                    assert.equal(other_model.id, reverses[0].id, "other remains in relationship. Expected: #{other_model.id}. Actual: #{reverses[0].id}")
                    done()

      it "Can manually delete a relationship by related_id (belongsTo)#{if unload then ' with unloaded model' else ''}", (done) ->
        Reverse.findOne {owner_id: {$ne: null}}, (err, reverse) ->
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
        Reverse.findOne {owner_id: {$ne: null}}, (err, reverse) ->
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
        Reverse.findOne {owner_id: {$ne: null}}, (err, reverse) ->
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
        Reverse.findOne {owner_id: {$ne: null}}, (err, reverse) ->
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
      related_key = 'reverses'
      related_id_accessor = 'reverse_ids'

      Owner.cursor({$one: true}).include(related_key).toModels (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner_id = owner.id
        relateds = owner.get(related_key).models
        related_ids = (related.id for related in relateds)
        assert.equal(2, relateds.length, "Loaded relateds. Expected: #{2}. Actual: #{relateds.length}")
        assert.ok(!_.difference(related_ids, owner.get(related_id_accessor)).length, "Got related_id from previous related. Expected: #{related_ids}. Actual: #{owner.get(related_id_accessor)}")

        (attributes = {})[related_key] = relateds
        new_owner = new Owner(attributes)
        owner1 = null; new_owner1 = null; new_owner_id = null

        assert.equal(0, owner.get(related_key).models.length, "Loaded related from previous related. Expected: #{0}. Actual: #{owner.get(related_key).models.length}")
        assert.equal(0, owner.get(related_id_accessor).length, "Loaded related from previous related. Expected: #{0}. Actual: #{owner.get(related_id_accessor).length}")
        assert.ok(!_.difference(related_ids, (related.id for related in new_owner.get(related_key).models)).length, "Loaded related from previous related. Expected: #{related_ids}. Actual: #{(related.id for related in new_owner.get(related_key).models)}")
        assert.ok(!_.difference(related_ids, new_owner.get(related_id_accessor)).length, "Got related_id from copied related. Expected: #{related_ids}. Actual: #{new_owner.get(related_id_accessor)}")

        queue = new Queue(1)
        queue.defer (callback) -> new_owner.save callback
        queue.defer (callback) -> owner.save callback

        # make sure nothing changed after save
        queue.defer (callback) ->
          new_owner_id = new_owner.id
          assert.ok(new_owner_id, 'had an id after after')

          assert.equal(0, owner.get(related_key).models.length, "Loaded related from previous related. Expected: #{0}. Actual: #{owner.get(related_key).models.length}")
          assert.equal(0, owner.get(related_id_accessor).length, "Loaded related from previous related. Expected: #{0}. Actual: #{owner.get(related_id_accessor).length}")
          assert.ok(!_.difference(related_ids, (related.id for related in new_owner.get(related_key).models)).length, "Loaded related from previous related. Expected: #{related_ids}. Actual: #{(related.id for related in new_owner.get(related_key).models)}")
          assert.ok(!_.difference(related_ids, new_owner.get(related_id_accessor)).length, "Got related_id from copied related. Expected: #{related_ids}. Actual: #{new_owner.get(related_id_accessor)}")
          callback()

        # load
        queue.defer (callback) -> Owner.find owner_id, (err, _owner) -> callback(err, owner1 = _owner)
        queue.defer (callback) -> Owner.find new_owner_id, (err, _owner) -> callback(err, new_owner1 = _owner)

        # check
        queue.defer (callback) ->

          owner1.get related_key, (err, relateds) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(0, relateds.length, "Loaded related from previous related. Expected: #{0}. Actual: #{relateds.length}")
            assert.equal(0, owner.get(related_id_accessor).length, "Loaded related from previous related. Expected: #{0}. Actual: #{owner.get(related_id_accessor).length}")

            new_owner1.get related_key, (err, relateds) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!_.difference(related_ids, (related.id for related in relateds)).length, "Loaded related from previous related. Expected: #{related_ids}. Actual: #{(related.id for related in relateds)}")
              assert.ok(!_.difference(related_ids, new_owner1.get(related_id_accessor)).length, "Got related_id from reloaded previous related. Expected: #{related_ids}. Actual: #{new_owner1.get(related_id_accessor)}")
              callback()

        queue.await done

    it 'Handles a get query for a hasMany relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'flats', (err, flats) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, flats.length, "Expected: #{2}. Actual: #{flats.length}")
          if test_model.relationIsEmbedded('flats')
            assert.deepEqual(test_model.toJSON().flats[0], flats[0].toJSON(), "Serialized embedded. Expected: #{test_model.toJSON().flats[0]}. Actual: #{flats[0].toJSON()}")
          done()

    it 'Handles an async get query for ids', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'flat_ids', (err, ids) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, ids.length, "Expected count: #{2}. Actual: #{ids.length}")
          done()

    it 'Handles a synchronous get query for ids after the relations are loaded', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'flats', (err, flats) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(test_model.get('flat_ids').length, flats.length, "Expected count: #{test_model.get('flat_ids').length}. Actual: #{flats.length}")
          assert.deepEqual(test_model.get('flat_ids')[0], flats[0].id, "Serialized id only. Expected: #{test_model.get('flat_ids')[0]}. Actual: #{flats[0].id}")
          done()

    it 'Handles a get query for a hasMany and belongsTo two sided relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found models')
          assert.equal(2, reverses.length, "Reverses Expected: #{2}. Actual: #{reverses.length}")

          if test_model.relationIsEmbedded('reverses')
            assert.deepEqual(test_model.toJSON().reverses[0], reverses[0].toJSON(), 'Serialized embedded')
          assert.deepEqual(test_model.get('reverse_ids')[0], reverses[0].id, 'serialized id only')
          reverse = reverses[0]

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'found owner models')
            if reverse.relationIsEmbedded('owner')
              assert.deepEqual(reverse.toJSON().owner_id, owner.id, "Serialized embedded. Expected: #{JSONUtils.stringify(reverse.toJSON().owner_id)}. Actual: #{JSONUtils.stringify(owner.id)}")
            assert.deepEqual(reverse.get('owner_id'), owner.id, "Serialized id only. Expected: #{reverse.get('owner_id')}. Actual: #{owner.id}")

            if Owner.cache
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "Owner Expected: #{JSONUtils.stringify(test_model.toJSON())}\nActual: #{JSONUtils.stringify(test_model.toJSON())}")
            else
              assert.equal(test_model.id, owner.id, "Owner Expected: #{test_model.id}\nActual: #{owner.id}")
            done()

    it 'Appends json for a related model', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        JSONUtils.renderRelated test_model, 'reverses', ['id', 'created_at'], (err, related_json) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(related_json.length, "json has a list of reverses")
          assert.equal(2, related_json.length, "Expected: #{2}. Actual: #{related_json.length}")
          for reverse in related_json
            assert.ok(reverse.id, "reverse has an id")
            assert.ok(reverse.created_at, "reverse has a created_at")
            assert.ok(!reverse.updated_at, "reverse doesn't have updated_at")
          done()

    it 'Handles a get query for a hasMany and belongsTo two sided relation as "as" fields', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'more_reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found models')
          assert.equal(2, reverses.length, "Reverses Expected: #{2}. Actual: #{reverses.length}")

          if test_model.relationIsEmbedded('more_reverses')
            assert.deepEqual(test_model.toJSON().reverses[0], reverses[0].toJSON(), 'Serialized embedded')
          assert.deepEqual(test_model.get('more_reverse_ids')[0], reverses[0].id, 'serialized id only')

          test_model.get 'reverses', (err, test_reverses) ->
            assert.ok(!err, "No errors: #{err}")
            for reverse in reverses
              assert.notEqual(test_reverse.id, reverse.id, "Expected: #{test_reverse.id} to not be: #{reverse.id}") for test_reverse in test_reverses

            reverse = reverses[0]
            reverse.get 'another_owner', (err, owner) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(owner, 'found owner models')
              if reverse.relationIsEmbedded('owner')
                assert.deepEqual(reverse.toJSON().another_owner_id, owner.id, "Serialized embedded. Expected: #{JSONUtils.stringify(reverse.toJSON().another_owner_id)}. Actual: #{JSONUtils.stringify(owner.id)}")
              assert.deepEqual(reverse.get('another_owner_id'), owner.id, "Serialized id only. Expected: #{reverse.get('another_owner_id')}. Actual: #{owner.id}")

              if Owner.cache
                assert.deepEqual(test_model.toJSON(), owner.toJSON(), "Owner Expected: #{JSONUtils.stringify(test_model.toJSON())}\nActual: #{JSONUtils.stringify(test_model.toJSON())}")
              else
                assert.equal(test_model.id, owner.id, "Owner Expected: #{test_model.id}\nActual: #{owner.id}")
              done()

    it 'Can include related (one-way hasMany) models', (done) ->
      Owner.cursor({$one: true}).include('flats').toJSON (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        assert.ok(test_model.flats, 'Has related flats')
        assert.equal(test_model.flats.length, 2, "Has the correct number of related flats \nExpected: #{2}\nActual: #{test_model.flats.length}")
        done()

    it 'Can include multiple related (one-way hasMany) models', (done) ->
      Owner.cursor({$one: true}).include('flats', 'reverses').toJSON (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        assert.ok(test_model.flats, 'Has related flats')
        assert.ok(test_model.reverses, 'Has related reverses')
        assert.equal(test_model.flats.length, 2, "Has the correct number of related flats \nExpected: #{2}\nActual: #{test_model.flats.length}")
        assert.equal(test_model.reverses.length, 2, "Has the correct number of related reverses \nExpected: #{test_model.reverses.length}\nActual: #{test_model.reverses.length}")

        for flat in test_model.flats
          assert.equal(test_model.id, flat.owner_id, "\nExpected: #{test_model.id}\nActual: #{flat.owner_id}")
        for reverse in test_model.reverses
          assert.equal(test_model.id, reverse.owner_id, "\nExpected: #{test_model.id}\nActual: #{reverse.owner_id}")
        done()

    it 'Can query on related (one-way hasMany) models', (done) ->
      Reverse.findOne {owner_id: {$ne: null}}, (err, reverse) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(reverse, 'found model')
        Owner.cursor({'reverses.name': reverse.get('name')}).toJSON (err, json) ->
          test_model = json[0]
          assert.ok(!err, "No errors: #{err}")
          assert.ok(test_model, 'found test model')
          assert.equal(test_model.id, reverse.get('owner_id'), "\nExpected: #{test_model.id}\nActual: #{reverse.get('owner_id')}")
          done()

    it 'Can query on related (one-way hasMany) models with included relations', (done) ->
      Reverse.findOne {owner_id: {$ne: null}}, (err, reverse) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(reverse, 'found model')

        Owner.cursor({'reverses.name': reverse.get('name')}).include('flats', 'reverses').toJSON (err, json) ->
          test_model = json[0]

          assert.ok(!err, "No errors: #{err}")
          assert.ok(test_model, 'found model')

          assert.ok(test_model.flats, 'Has related flats')
          assert.ok(test_model.reverses, 'Has related reverses')

          assert.equal(test_model.flats.length, 2, "Has the correct number of related flats \nExpected: #{2}\nActual: #{test_model.flats.length}")
          assert.equal(test_model.reverses.length, 2, "Has the correct number of related reverses \nExpected: #{2}\nActual: #{test_model.reverses.length}")

          for flat in test_model.flats
            assert.equal(test_model.id, flat.owner_id, "\nExpected: #{test_model.id}\nActual: #{flat.owner_id}")
          for reverse in test_model.reverses
            assert.equal(test_model.id, reverse.owner_id, "\nExpected: #{test_model.id}\nActual: #{reverse.owner_id}")
          done()

    it 'Clears its reverse relations on set when the reverse relation is loaded (one-way hasMany)', (done) ->
      Owner.cursor().include('reverses').toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found models')
          assert.equal(reverses.length, 2, 'Found reverses')
          for reverse in reverses
            assert.equal(reverse.get('owner_id'), owner.id, 'Reverse has an owner_id')

          removed_reverse = reverses[1]
          owner.set('reverses', [reverses[0]])
          assert.equal(owner.get('reverses').length, 1, "It has the correct number of relations after set\nExpected: #{1}\nActual: #{owner.get('reverses').length}")

          assert.equal(removed_reverse.get('owner_id'), null, 'Reverse relation has its foreign key set to null')

          owner.get 'reverses', (err, new_reverses) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(new_reverses.length, 1, "Relations loaded asynchronously have the correct length\nExpected: #{1}\nActual: #{new_reverses.length}")
            done()

    it 'Clears its reverse relations on save (one-way hasMany)', (done) ->
      Owner.cursor().include('reverses').toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found models')
          assert.equal(reverses.length, 2, 'Found reverses')
          for reverse in reverses
            assert.equal(reverse.get('owner_id'), owner.id, 'Reverse has an owner_id')

          removed_reverse = reverses[1]
          owner.set({reverses: [reverses[0]]})
          assert.equal(owner.get('reverses').length, 1, "It has the correct number of relations after set\nExpected: #{1}\nActual: #{owner.get('reverses').length}")
          assert.equal(removed_reverse.get('owner_id'), null, 'Reverse relation has its foreign key set to null')

          owner.save (err, owner) ->
            Reverse.find {owner_id: owner.id}, (err, new_reverses) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(1, new_reverses.length, "Relations loaded from store have the correct length\nExpected: #{1}\nActual: #{new_reverses.length}")
              done()

    it 'Clears its reverse relations on delete when the reverse relation is loaded (one-way hasMany)', (done) ->
      Owner.cursor().include('reverses').toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found model')

          owner.destroy (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            Reverse.find {owner_id: owner.id}, (err, null_reverses) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(null_reverses.length, 0, 'No reverses found for this owner after save')
              done()

    it 'Clears its reverse relations on delete when the reverse relation isnt loaded (one-way hasMany)', (done) ->
      Owner.findOne (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found model')

          owner.destroy (err, owner) ->
            assert.ok(!err, "No errors: #{err}")

            Reverse.find {owner_id: owner.id}, (err, null_reverses) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(null_reverses.length, 0, 'No reverses found for this owner after save')
              done()

    it 'Should be able to count relationships', (done) ->
      Owner.findOne (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')

        Reverse.count {owner_id: owner.id}, (err, count) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, count, "Counted reverses. Expected: 2. Actual: #{count}")
          done()

    it 'Should be able to count relationships with paging', (done) ->
      Owner.findOne (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')

        Reverse.cursor({owner_id: owner.id, $page: true}).toJSON (err, paging_info) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(0, paging_info.offset, "Has offset. Expected: 0. Actual: #{paging_info.offset}")
          assert.equal(2, paging_info.total_rows, "Counted reverses. Expected: 2. Actual: #{paging_info.total_rows}")
          done()

    backlinkTests = (virtual) ->
      it "Should update backlinks using set (#{if virtual then 'virtual' else 'no modifiers'})", (done) ->
        checkReverseFn = (reverses, expected_owner) -> return (callback) ->
          assert.ok(reverses, 'Reverses exists')
          for reverse in reverses
            assert.equal(expected_owner, reverse.get('owner'), "Reverse owner is correct. Expected: #{expected_owner}. Actual: #{reverse.get('owner')}")
          callback()

        Owner.cursor().limit(2).include('reverses').toModels (err, owners) ->
          if virtual # set as virtual relationship after including reverse
            relation = Owner.relation('reverses')
            relation.virtual = true

          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, owners.length, "Found owners. Expected: 2. Actual: #{owners.length}")

          owner0 = owners[0]; owner0_id = owner0.id; reverses0 = _.clone(owner0.get('reverses').models)
          owner1 = owners[1]; owner1_id = owner1.id; reverses1 = _.clone(owner1.get('reverses').models)
          new_reverses0 = [reverses0[0], reverses1[0]]

          assert.equal(2, owner0.get('reverses').models.length, "Owner0 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
          assert.equal(2, owner1.get('reverses').models.length, "Owner1 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

          queue = new Queue(1)
          queue.defer checkReverseFn(reverses0, owner0)
          queue.defer checkReverseFn(reverses1, owner1)
          queue.defer (callback) ->
            owner0.set({reverses: new_reverses0})

            if virtual # doesn't remove from other
              assert.equal(2, owner0.get('reverses').models.length, "Owner0 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
              assert.equal(2, owner1.get('reverses').models.length, "Owner1 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")
            else
              assert.equal(2, owner0.get('reverses').models.length, "Owner0 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
              assert.equal(1, owner1.get('reverses').models.length, "Owner1 has 1 reverses.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

            queue.defer checkReverseFn(new_reverses0, owner0) # confirm it moved
            assert.equal(null, reverses0[1].get('owner'), "Reverse owner is cleared.\nExpected: #{null}.\nActual: #{JSONUtils.stringify(reverses0[1].get('owner'))}")
            assert.equal(owner1, reverses1[1].get('owner'), "Reverse owner is cleared.\nExpected: #{JSONUtils.stringify(owner1)}.\nActual: #{JSONUtils.stringify(reverses1[1].get('owner'))}")
            callback()

          # save and recheck
          queue.defer (callback) -> owner0.save callback
          queue.defer (callback) -> owner1.save callback
          queue.defer (callback) ->
            Owner.cursor({$ids: [owner0.id, owner1.id]}).limit(2).include('reverses').toModels (err, owners) ->
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
              reverses0b = _.clone(owner0.get('reverses').models)
              reverses1b = _.clone(owner1.get('reverses').models)

              if virtual # doesn't save
                assert.equal(2, owner0.get('reverses').models.length, "Owner0b has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
                assert.equal(2, owner1.get('reverses').models.length, "Owner1b has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")
              else
                assert.equal(2, owner0.get('reverses').models.length, "Owner0b has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
                assert.equal(1, owner1.get('reverses').models.length, "Owner1b has 1 reverses.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

                queue.defer checkReverseFn(reverses0b, owner0) # confirm it moved
                assert.equal(null, reverses0[1].get('owner'), "Reverse owner is cleared.\nExpected: #{null}.\nActual: #{JSONUtils.stringify(reverses0[1].get('owner'))}")
                queue.defer checkReverseFn(reverses1b, owner1) # confirm it moved
              callback()

          queue.await (err) ->
            assert.ok(!err, "No errors: #{err}")
            done()

      it "Should update backlinks using the collection directly (#{if virtual then 'virtual' else 'no modifiers'})", (done) ->
        checkReverseFn = (reverses, expected_owner) -> return (callback) ->
          assert.ok(reverses, 'Reverses exists')
          for reverse in reverses
            assert.equal(expected_owner, reverse.get('owner'), "Reverse owner is correct. Expected: #{expected_owner}. Actual: #{reverse.get('owner')}")
          callback()

        Owner.cursor().limit(2).include('reverses').toModels (err, owners) ->
          if virtual # set as virtual relationship after including reverse
            relation = Owner.relation('reverses')
            relation.virtual = true

          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, owners.length, "Found owners. Expected: 2. Actual: #{owners.length}")

          owner0 = owners[0]; owner0_id = owner0.id; reverses0 = _.clone(owner0.get('reverses').models)
          owner1 = owners[1]; owner1_id = owner1.id; reverses1 = _.clone(owner1.get('reverses').models)
          moved_reverse0 = reverses1[0]

          assert.equal(2, owner0.get('reverses').models.length, "Owner0 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
          assert.equal(2, owner1.get('reverses').models.length, "Owner1 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

          queue = new Queue(1)
          queue.defer checkReverseFn(reverses0, owner0)
          queue.defer checkReverseFn(reverses1, owner1)
          queue.defer (callback) ->
            reverses = owner0.get('reverses')
            reverses.add(moved_reverse0)

            if virtual # doesn't remove from other
              assert.equal(3, owner0.get('reverses').models.length, "Owner0 has 3 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
              assert.equal(2, owner1.get('reverses').models.length, "Owner1 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")
            else
              assert.equal(3, owner0.get('reverses').models.length, "Owner0 has 3 reverses.\nExpected: #{3}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
              assert.equal(1, owner1.get('reverses').models.length, "Owner1 has 1 reverses.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

            queue.defer checkReverseFn([moved_reverse0], owner0) # confirm it moved
            callback()

          # save and recheck
          queue.defer (callback) -> owner0.save callback
          queue.defer (callback) -> owner1.save callback
          queue.defer (callback) ->
            Owner.cursor({$ids: [owner0.id, owner1.id]}).limit(2).include('reverses').toModels (err, owners) ->
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
              reverses0b = _.clone(owner0.get('reverses').models)
              reverses1b = _.clone(owner1.get('reverses').models)

              if virtual # doesn't save
                assert.equal(2, owner0.get('reverses').models.length, "Owner0b has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
                assert.equal(2, owner1.get('reverses').models.length, "Owner1b has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")
              else
                assert.equal(3, owner0.get('reverses').models.length, "Owner0b has 3 reverses.\nExpected: #{3}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
                assert.equal(1, owner1.get('reverses').models.length, "Owner1b has 1 reverses.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

                queue.defer checkReverseFn(reverses0b, owner0) # confirm it moved
                reverses = owner0.get('reverses')
                moved_reverse0b = reverses.get(moved_reverse0.id)
                assert.ok(moved_reverse0b, "Reverse was moved.")
                queue.defer checkReverseFn([moved_reverse0b], owner0) # confirm it moved

              callback()

          queue.await (err) ->
            assert.ok(!err, "No errors: #{err}")
            done()

    backlinkTests(false)
    backlinkTests(true)

    it 'does not serialize virtual attributes', (done) ->
      Owner.cursor().include('flats').toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'Reverse found model')

        assert.equal(2, owner.get('flats').length, "Virtual flat exists. Expected: #{2}. Actual: #{owner.get('flats').length}")

        relation = owner.relation('flats')
        relation.virtual = true

        flats = owner.get('flats')
        owner.set({flats: []})
        owner.save {flats: flats}, (err) ->
          assert.ok(!err, "No errors: #{err}")

          Owner.cache.reset(owner.id) if Owner.cache
          Owner.find owner.id, (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(0, owner.get('flats').length, "Virtual flat is not saved. Expected: #{0}. Actual: #{owner.get('flats').length}")
            done()
