path = require 'path'
assert = assert or require?('chai').assert

NodeUtils = require '../../../lib/node_utils'

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "Node: Many to Many with resetSchemasByDirectory #{options.$parameter_tags or ''}#{options.$tags}", ->
    Owner = Reverse = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      # manually clear the cache so the model can be rebootstrapped
      delete require.cache[require.resolve('./directory/folder/reverse')]
      delete require.cache[require.resolve('./directory/owner')]
      Reverse = require './directory/folder/reverse'
      Owner = require './directory/owner'

      # pre-configure
      Reverse::urlRoot = "#{DATABASE_URL}/reverses"
      Reverse::schema = _.defaults({
        owners: -> ['hasMany', Owner]
      }, BASE_SCHEMA)
      Reverse::sync = SYNC(Reverse)

      Owner::urlRoot = "#{DATABASE_URL}/owners"
      Owner::schema = _.defaults({
        reverses: -> ['hasMany', Reverse]
      }, BASE_SCHEMA)
      Owner::sync = SYNC(Owner)

    after (callback) ->
      NodeUtils.resetSchemasByDirectory path.join(__dirname, 'directory'), callback

    beforeEach (callback) ->
      relation = Owner.relation('reverses')
      delete relation.virtual
      MODELS = {}

      queue = new Queue(1)
      queue.defer (callback) -> NodeUtils.resetSchemasByDirectory path.join(__dirname, 'directory'), callback
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

    it 'Can create a model and load a related model by id (hasMany)', (done) ->
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

    it 'Can create a model and load a related model by id (hasMany)', (done) ->
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

    it 'Can create a model and load a related model by id (belongsTo)', (done) ->
      Owner.cursor({$values: 'id'}).limit(4).toJSON (err, owner_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, owner_ids.length, "found 4 owners. Actual: #{owner_ids.length}")

        new_model = new Reverse()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({owners: owner_ids})
          new_model.get 'owners', (err, owners) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(4, owners.length, "loaded correct model. Expected: #{4}. Actual: #{owners.length}")
            assert.equal(_.difference(owner_ids, (test.id for test in owners)).length, 0, "expected owners: #{_.difference(owner_ids, (owner.id for owner in owners))}")
            done()

    it 'Can create a model and load a related model by id (belongsTo)', (done) ->
      Owner.cursor({$values: 'id'}).limit(4).toJSON (err, owner_ids) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(4, owner_ids.length, "found 4 owners. Actual: #{owner_ids.length}")

        new_model = new Reverse()
        new_model.save (err) ->
          assert.ok(!err, "No errors: #{err}")
          new_model.set({owner_ids: owner_ids})
          new_model.get 'owners', (err, owners) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(4, owners.length, "loaded correct model. Expected: #{4}. Actual: #{owners.length}")
            assert.equal(_.difference(owner_ids, (test.id for test in owners)).length, 0, "expected owners: #{_.difference(owner_ids, (owner.id for owner in owners))}")
            done()

    it 'Can create a model and update the relationship (belongsTo)', (done) ->
      related_key = 'reverses'
      related_id_accessor = 'reverse_ids'

      Owner.cursor().include(related_key).toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner_id = owner.id
        relateds = owner.get(related_key).models
        related_ids = (related.id for related in relateds)
        assert.ok(2, relateds.length, "Loaded relateds. Expected: #{2}. Actual: #{relateds.length}")
        assert.ok(!_.difference(related_ids, owner.get(related_id_accessor)).length, "Got related_id from previous related. Expected: #{related_ids}. Actual: #{owner.get(related_id_accessor)}")

        (attributes = {})[related_key] = relateds
        new_owner = new Owner(attributes)
        owner1 = null; new_owner1 = null; new_owner_id = null

        assert.ok(!_.difference(related_ids, (related.id for related in owner.get(related_key).models)).length, "Loaded related from previous related. Expected: #{related_ids}. Actual: #{(related.id for related in owner.get(related_key).models)}")
        assert.ok(!_.difference(related_ids, owner.get(related_id_accessor)).length, "Got related_id from previous related. Expected: #{related_ids}. Actual: #{owner.get(related_id_accessor)}")
        assert.ok(!_.difference(related_ids, (related.id for related in new_owner.get(related_key).models)).length, "Loaded related from previous related. Expected: #{related_ids}. Actual: #{(related.id for related in new_owner.get(related_key).models)}")
        assert.ok(!_.difference(related_ids, new_owner.get(related_id_accessor)).length, "Got related_id from copied related. Expected: #{related_ids}. Actual: #{new_owner.get(related_id_accessor)}")

        queue = new Queue(1)
        queue.defer (callback) -> new_owner.save callback
        queue.defer (callback) -> owner.save callback

        # make sure nothing changed after save
        queue.defer (callback) ->
          new_owner_id = new_owner.id
          assert.ok(new_owner_id, 'had an id after after')

          assert.ok(!_.difference(related_ids, (related.id for related in owner.get(related_key).models)).length, "Loaded related from previous related. Expected: #{related_ids}. Actual: #{(related.id for related in owner.get(related_key).models)}")
          assert.ok(!_.difference(related_ids, owner.get(related_id_accessor)).length, "Got related_id from previous related. Expected: #{related_ids}. Actual: #{owner.get(related_id_accessor)}")
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
            assert.ok(!_.difference(related_ids, (related.id for related in relateds)).length, "Loaded related from previous related. Expected: #{related_ids}. Actual: #{(related.id for related in relateds)}")
            assert.ok(!_.difference(related_ids, owner1.get(related_id_accessor)).length, "Got related_id from reloaded previous related. Expected: #{related_ids}. Actual: #{owner1.get(related_id_accessor)}")

            new_owner1.get related_key, (err, related) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(!_.difference(related_ids, (related.id for related in relateds)).length, "Loaded related from previous related. Expected: #{related_ids}. Actual: #{(related.id for related in relateds)}")
              assert.ok(!_.difference(related_ids, new_owner1.get(related_id_accessor)).length, "Got related_id from reloaded previous related. Expected: #{related_ids}. Actual: #{new_owner1.get(related_id_accessor)}")
              callback()

        queue.await done

    it 'Handles a get query for a hasMany and hasMany two sided relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        test_model.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses.length, 'found related reverses')
          if test_model.relationIsEmbedded('reverses')
            assert.deepEqual(test_model.toJSON().reverses[0], reverses[0].toJSON(), "Serialized embedded. Expected: #{test_model.toJSON().reverses}. Actual: #{reverses[0].toJSON()}")
          else
            assert.deepEqual(test_model.get('reverse_ids')[0], reverses[0].id, "Serialized id only. Expected: #{test_model.get('reverse_ids')[0]}. Actual: #{reverses[0].id}")
          reverse = reverses[0]

          reverse.get 'owners', (err, owners) ->
            assert.ok(!err, "No errors: #{err}")
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

    it 'Can include related (two-way hasMany) models', (done) ->
      Owner.cursor({$one: true}).include('reverses').toJSON (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        assert.ok(test_model.reverses, 'Has related reverses')
        assert.equal(test_model.reverses.length, 2, "Has the correct number of related reverses \nExpected: #{2}\nActual: #{test_model.reverses.length}")
        done()

    it 'Can query on related (two-way hasMany) models', (done) ->
      Reverse.findOne (err, reverse) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(reverse, 'found model')
        Owner.cursor({'reverses.name': reverse.get('name')}).toJSON (err, json) ->
          test_model = json[0]
          assert.ok(!err, "No errors: #{err}")
          assert.ok(test_model, 'found model')
          assert.equal(json.length, 1, "Found the correct number of owners \nExpected: #{1}\nActual: #{json.length}")
          done()

    it 'Can query on related (two-way hasMany) models with included relations', (done) ->
      Reverse.findOne (err, reverse) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(reverse, 'found model')
        Owner.cursor({'reverses.name': reverse.get('name')}).include('reverses').toJSON (err, json) ->
          test_model = json[0]
          assert.ok(!err, "No errors: #{err}")
          assert.ok(test_model, 'found model')
          assert.ok(test_model.reverses, 'Has related reverses')
          assert.equal(test_model.reverses.length, 2, "Has the correct number of related reverses \nExpected: #{2}\nActual: #{test_model.reverses.length}")
          done()

    it 'Clears its reverse relations on delete when the reverse relation is loaded', (done) ->
      Owner.cursor().include('reverses').toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found model')

          owner.destroy (err, owner) ->
            assert.ok(!err, "No errors: #{err}")

            Owner.relation('reverses').join_table.find {owner_id: owner.id}, (err, null_reverses) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(null_reverses.length, 0, 'No reverses found for this owner after save')
              done()

    it 'Clears its reverse relations on delete when the reverse relation isnt loaded (one-way hasMany)', (done) ->
      Owner.cursor().toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found model')

          owner.destroy (err, owner) ->
            assert.ok(!err, "No errors: #{err}")

            Owner.relation('reverses').join_table.find {owner_id: owner.id}, (err, null_reverses) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(null_reverses.length, 0, 'No reverses found for this owner after save')
              done()

    it 'Can query on a ManyToMany relation by related id', (done) ->
      Owner.findOne (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        Reverse.cursor({owner_id: owner.id}).toModels (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found models')
          assert.equal(reverses.length, 2, "Found the correct number of reverses\n expected: #{2}, actual: #{reverses.length}")
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
            assert.ok(_.contains(reverse.get('owners').models, expected_owner), "Reverse owner is in the list. Expected: #{expected_owner}. Actual: #{reverse.get('owners').models}")
          callback()

        Owner.cursor().limit(2).include('reverses').toModels (err, owners) ->
          if virtual # set as virtual relationship after including reverse
            relation = Owner.relation('reverses')
            relation.virtual = true

          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, owners.length, "Found owners. Expected: 2. Actual: #{owners.length}")

          owner0 = owners[0]; owner0_id = owner0.id; reverses0 = _.clone(owner0.get('reverses').models); reverses0a = null; reverses0b = null
          owner1 = owners[1]; owner1_id = owner1.id; reverses1 = _.clone(owner1.get('reverses').models); reverses1a = null; reverses1b = null
          new_reverses0 = [reverses0[0], reverses1[0]]

          queue = new Queue(1)
          queue.defer checkReverseFn(reverses0, owner0)
          queue.defer checkReverseFn(reverses1, owner1)
          assert.equal(1, reverses0[0].get('owners').models.length, "Reverse0_0 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses0[0].get('owners').models.length)}")
          assert.equal(1, reverses0[1].get('owners').models.length, "Reverse0_1 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses0[1].get('owners').models.length)}")
          assert.equal(1, reverses1[0].get('owners').models.length, "Reverse1_0 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses1[0].get('owners').models.length)}")
          assert.equal(1, reverses1[1].get('owners').models.length, "Reverse1_1 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses1[1].get('owners').models.length)}")

          queue.defer (callback) ->
            owner0.set({reverses: new_reverses0})
            queue.defer checkReverseFn(new_reverses0, owner0) # confirm it moved
            queue.defer checkReverseFn(reverses1, owner1)

            reverses0a = _.clone(owners[0].get('reverses').models)
            reverses1a = _.clone(owners[1].get('reverses').models)

            assert.equal(2, owner0.get('reverses').models.length, "Owner0 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
            assert.equal(2, owner1.get('reverses').models.length, "Owner1 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

            assert.equal(1, reverses0[0].get('owners').models.length, "Reverse0_0 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses0[0].get('owners').models.length)}")
            assert.equal(0, reverses0[1].get('owners').models.length, "Reverse0_1 has no owners.\nExpected: #{0}.\nActual: #{JSONUtils.stringify(reverses0[1].get('owners').models)}")
            assert.equal(2, reverses1[0].get('owners').models.length, "Reverse1_0 has 2 owners.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(reverses1[0].get('owners').models)}")
            assert.equal(1, reverses1[1].get('owners').models.length, "Reverse1_1 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses1[1].get('owners').models.length)}")
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

              assert.equal(2, owner0.get('reverses').models.length, "Owner0b has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
              assert.equal(2, owner1.get('reverses').models.length, "Owner1b has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

              getReverseCount = (reverse) ->
                return 1 if virtual
                in_0 = _.find(reverses0, (test) -> test.id is reverse.id)
                in_new = _.find(new_reverses0, (test) -> test.id is reverse.id)
                if in_0
                  return if in_new then 1 else 0
                else
                  return if in_new then 2 else 1

              queue.defer checkReverseFn(reverses0b, owner0) # confirm it moved
              assert.equal(null, reverses0[1].get('owner'), "Reverse owner is cleared.\nExpected: #{null}.\nActual: #{JSONUtils.stringify(reverses0[1].get('owner'))}")
              queue.defer checkReverseFn(reverses1b, owner1) # confirm it moved

              assert.equal(getReverseCount(reverses0b[0]), reverses0b[0].get('owners').models.length, "Reverse0_0b (#{reverses0b[0].id}) has expected owners.\nExpected: #{getReverseCount(reverses0b[0])}.\nActual: #{JSONUtils.stringify(reverses0b[0].get('owners').models)}")
              assert.equal(getReverseCount(reverses0b[1]), reverses0b[1].get('owners').models.length, "Reverse0_1b (#{reverses0b[1].id}) has expected owners.\nExpected: #{getReverseCount(reverses0b[1])}.\nActual: #{JSONUtils.stringify(reverses0b[1].get('owners').models)}")
              assert.equal(getReverseCount(reverses1b[0]), reverses1b[0].get('owners').models.length, "Reverse1_0b (#{reverses1b[0].id}) has expected owners.\nExpected: #{getReverseCount(reverses1b[0])}.\nActual: #{JSONUtils.stringify(reverses1b[0].get('owners').models)}")
              assert.equal(getReverseCount(reverses1b[1]), reverses1b[1].get('owners').models.length, "Reverse1_0b (#{reverses1b[1].id}) has expected owners.\nExpected: #{getReverseCount(reverses1b[1])}.\nActual: #{JSONUtils.stringify(reverses1b[0].get('owners').models)}")

              callback()

          queue.await (err) ->
            assert.ok(!err, "No errors: #{err}")
            done()

      it "Should update backlinks using the collection directly (#{if virtual then 'virtual' else 'no modifiers'})", (done) ->
        checkReverseFn = (reverses, expected_owner) -> return (callback) ->
          assert.ok(reverses, 'Reverses exists')
          for reverse in reverses
            assert.ok(_.contains(reverse.get('owners').models, expected_owner), "Reverse owner is in the list. Expected: #{expected_owner}. Actual: #{reverse.get('owners').models}")
          callback()

        Owner.cursor().limit(2).include('reverses').toModels (err, owners) ->
          if virtual # set as virtual relationship after including reverse
            relation = Owner.relation('reverses')
            relation.virtual = true

          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, owners.length, "Found owners. Expected: 2. Actual: #{owners.length}")

          owner0 = owners[0]; owner0_id = owner0.id; reverses0 = _.clone(owner0.get('reverses').models); reverses0a = null; reverses0b = null
          owner1 = owners[1]; owner1_id = owner1.id; reverses1 = _.clone(owner1.get('reverses').models); reverses1a = null; reverses1b = null
          shared_reverse0 = reverses1[0]

          queue = new Queue(1)
          queue.defer checkReverseFn(reverses0, owner0)
          queue.defer checkReverseFn(reverses1, owner1)
          assert.equal(1, reverses0[0].get('owners').models.length, "Reverse0_0 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses0[0].get('owners').models.length)}")
          assert.equal(1, reverses0[1].get('owners').models.length, "Reverse0_1 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses0[1].get('owners').models.length)}")
          assert.equal(1, reverses1[0].get('owners').models.length, "Reverse1_0 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses1[0].get('owners').models.length)}")
          assert.equal(1, reverses1[1].get('owners').models.length, "Reverse1_1 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses1[1].get('owners').models.length)}")

          queue.defer (callback) ->
            reverses = owner0.get('reverses')
            reverses.add(shared_reverse0)

            queue.defer checkReverseFn([shared_reverse0], owner0) # confirm it moved
            queue.defer checkReverseFn(reverses1, owner1)

            reverses0a = _.clone(owners[0].get('reverses').models)
            reverses1a = _.clone(owners[1].get('reverses').models)

            assert.equal(3, owner0.get('reverses').models.length, "Owner0 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner0.get('reverses').models.length)}")
            assert.equal(2, owner1.get('reverses').models.length, "Owner1 has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

            assert.equal(1, reverses0[0].get('owners').models.length, "Reverse0_0 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses0[0].get('owners').models.length)}")
            assert.equal(1, reverses0[1].get('owners').models.length, "Reverse0_1 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses0[1].get('owners').models.length)}")
            assert.equal(2, reverses1[0].get('owners').models.length, "Reverse1_0 has 2 owners.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(reverses1[0].get('owners').models)}")
            assert.equal(1, reverses1[1].get('owners').models.length, "Reverse1_1 has 1 owner.\nExpected: #{1}.\nActual: #{JSONUtils.stringify(reverses1[1].get('owners').models.length)}")
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
                assert.equal(2, owner1.get('reverses').models.length, "Owner1b has 2 reverses.\nExpected: #{2}.\nActual: #{JSONUtils.stringify(owner1.get('reverses').models.length)}")

              getReverseCount = (reverse) ->
                return 1 if virtual
                return if shared_reverse0.id is reverse.id then 2 else 1

              queue.defer checkReverseFn(reverses0b, owner0) # confirm it moved
              assert.equal(null, reverses0[1].get('owner'), "Reverse owner is cleared.\nExpected: #{null}.\nActual: #{JSONUtils.stringify(reverses0[1].get('owner'))}")
              queue.defer checkReverseFn(reverses1b, owner1) # confirm it moved

              assert.equal(getReverseCount(reverses0b[0]), reverses0b[0].get('owners').models.length, "Reverse0_0b has expected owners.\nExpected: #{getReverseCount(reverses0b[0])}.\nActual: #{JSONUtils.stringify(reverses0b[0].get('owners').models)}")
              assert.equal(getReverseCount(reverses0b[1]), reverses0b[1].get('owners').models.length, "Reverse0_1b has expected owners.\nExpected: #{getReverseCount(reverses0b[1])}.\nActual: #{JSONUtils.stringify(reverses0b[1].get('owners').models)}")
              assert.equal(getReverseCount(reverses1b[0]), reverses1b[0].get('owners').models.length, "Reverse1_0b has expected owners.\nExpected: #{getReverseCount(reverses1b[0])}.\nActual: #{JSONUtils.stringify(reverses1b[0].get('owners').models)}")
              assert.equal(getReverseCount(reverses1b[1]), reverses1b[1].get('owners').models.length, "Reverse1_0b has expected owners.\nExpected: #{getReverseCount(reverses1b[1])}.\nActual: #{JSONUtils.stringify(reverses1b[0].get('owners').models)}")

              callback()

          queue.await (err) ->
            assert.ok(!err, "No errors: #{err}")
            done()

    # TODO: get these working again
    # backlinkTests(false)
    # backlinkTests(true)

    it 'does not serialize virtual attributes', (done) ->
      Owner.cursor().include('reverses').toModel (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'Reverse found model')

        assert.equal(2, owner.get('reverses').length, "Virtual flat exists. Expected: #{2}. Actual: #{owner.get('reverses').length}")

        relation = owner.relation('reverses')
        relation.virtual = true

        reverses = owner.get('reverses')
        owner.set({reverses: []})
        owner.save {reverses: reverses}, (err) ->
          assert.ok(!err, "No errors: #{err}")

          Owner.cache.reset(owner.id) if Owner.cache
          Owner.find owner.id, (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(0, owner.get('reverses').length, "Virtual flat is not saved. Expected: #{0}. Actual: #{owner.get('reverses').length}")
            done()
