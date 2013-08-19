util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
bbCallback = Utils.bbCallback
JSONUtils = require '../../../lib/json_utils'

runTests = (options, cache, embed, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  require('../../../lib/cache').configure(if cache then {max: 100} else null) # configure caching

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat)

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    @schema: _.defaults({
      owner: -> ['belongsTo', Owner]
      another_owner: -> ['belongsTo', Owner, as: 'more_reverses']
    }, BASE_SCHEMA)
    sync: SYNC(Reverse)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    @schema: _.defaults({
      flats: -> ['hasMany', Flat]
      reverses: -> ['hasMany', Reverse]
      more_reverses: -> ['hasMany', Reverse, as: 'another_owner', ids_accessor: 'more_reverses_ids']
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  describe "hasMany (cache: #{cache} embed: #{embed})", ->

    before (done) -> return done() unless options.before; options.before([Flat, Reverse, Owner], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      require('../../../lib/cache').reset() # reset cache
      MODELS = {}

      queue = new Queue(1)

      # destroy all
      queue.defer (callback) -> Utils.resetSchemas [Flat, Reverse, Owner], callback

      # create all
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create(Flat, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.more_reverse = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owner_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err))

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.set({
              flats: [MODELS.flat.pop(), MODELS.flat.pop()]
              reverses: [reverse1 = MODELS.reverse.pop(), reverse2 = MODELS.reverse.pop()]
              more_reverses: [MODELS.more_reverse.pop(), MODELS.more_reverse.pop()]
            })
            owner.save {}, Utils.bbCallback callback

        save_queue.await callback

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
              assert.deepEqual(reverse.toJSON().owner_id, owner.id, "Serialized embedded. Expected: #{util.inspect(reverse.toJSON().owner_id)}. Actual: #{util.inspect(owner.id)}")
            assert.deepEqual(reverse.get('owner_id'), owner.id, "Serialized id only. Expected: #{reverse.get('owner_id')}. Actual: #{owner.id}")

            if Owner.cache
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "Owner Expected: #{util.inspect(test_model.toJSON())}\nActual: #{util.inspect(test_model.toJSON())}")
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
          assert.deepEqual(test_model.get('more_reverses_ids')[0], reverses[0].id, 'serialized id only')


          test_model.get 'reverses', (err, test_reverses) ->

            for reverse in reverses
              assert.notEqual(test_reverse.id, reverse.id, "Expected: #{test_reverse.id} to not be: #{reverse.id}") for test_reverse in test_reverses

            reverse = reverses[0]
            reverse.get 'another_owner', (err, owner) ->
              assert.ok(!err, "No errors: #{err}")
              assert.ok(owner, 'found owner models')
              if reverse.relationIsEmbedded('owner')
                assert.deepEqual(reverse.toJSON().another_owner_id, owner.id, "Serialized embedded. Expected: #{util.inspect(reverse.toJSON().another_owner_id)}. Actual: #{util.inspect(owner.id)}")
              assert.deepEqual(reverse.get('another_owner_id'), owner.id, "Serialized id only. Expected: #{reverse.get('another_owner_id')}. Actual: #{owner.id}")

              if Owner.cache
                assert.deepEqual(test_model.toJSON(), owner.toJSON(), "Owner Expected: #{util.inspect(test_model.toJSON())}\nActual: #{util.inspect(test_model.toJSON())}")
              else
                assert.equal(test_model.id, owner.id, "Owner Expected: #{test_model.id}\nActual: #{owner.id}")
              done()

#
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
      Reverse.findOne (err, reverse) ->
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
      Owner.cursor({$one: true, $include: 'reverses'}).toModels (err, owner) ->
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
      Owner.cursor({$one: true, $include: 'reverses'}).toModels (err, owner) ->
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

          owner.save {}, Utils.bbCallback (err, owner) ->
            Reverse.find {owner_id: owner.id}, (err, new_reverses) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(1, new_reverses.length, "Relations loaded from store have the correct length\nExpected: #{1}\nActual: #{new_reverses.length}")
              done()

    it 'Clears its reverse relations on delete when the reverse relation is loaded (one-way hasMany)', (done) ->
      Owner.cursor({$one: true, $include: 'reverses'}).toModels (err, owner) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(owner, 'found model')
        owner.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found model')

          owner.destroy Utils.bbCallback (err, owner) ->
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

          owner.destroy Utils.bbCallback (err, owner) ->
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

    it 'Should manage backlinks (no modifiers)', (done) ->
      checkReverseFn = (reverses, expected_owner) -> return (callback) ->
        assert.ok(reverses, "Reverses exists")
        for reverse in reverses
          assert.equal(expected_owner, reverse.get('owner'), "Reverse owner is correct. Expected: #{expected_owner}. Actual: #{reverse.get('owner')}")
        callback()

      Owner.cursor().limit(2).include('reverses').toModels (err, owners) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(2, owners.length, "Found owners. Expected: 2. Actual: #{owners.length}")

        reverses0 = _.clone(owners[0].get('reverses').models); owner0 = owners[0]
        reverses1 = _.clone(owners[1].get('reverses').models); owner1 = owners[1]
        new_reverses0 = [reverses0[0], reverses1[0]]

        queue = new Queue(1)
        queue.defer checkReverseFn(reverses0, owner0)
        queue.defer checkReverseFn(reverses1, owner1)
        queue.defer (callback) ->
          owner0.set({reverses: new_reverses0})

          assert.equal(2, owner0.get('reverses').models.length, "Owner0 has 2 reverses.\nExpected: #{2}.\nActual: #{util.inspect(owner0.get('reverses').models.length)}")

          queue.defer checkReverseFn(new_reverses0, owner0) # confirm it moved
          assert.equal(null, reverses0[1].get('owner'), "Reverse owner is cleared.\nExpected: #{null}.\nActual: #{util.inspect(reverses0[1].get('owner'))}")
          assert.equal(owner1, reverses1[1].get('owner'), "Reverse owner is cleared.\nExpected: #{util.inspect(owner1)}.\nActual: #{util.inspect(reverses1[1].get('owner'))}")
          callback()

        # save and recheck
        queue.defer (callback) -> owner0.save {}, bbCallback callback
        queue.defer (callback) -> owner1.save {}, bbCallback callback
        queue.defer (callback) ->
          Owner.cursor({$ids: [owner0.id, owner1.id]}).limit(2).include('reverses').toModels (err, owners) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(2, owners.length, "Found owners. Expected: 2. Actual: #{owners.length}")
            reverses0b = _.clone(owners[0].get('reverses').models); owner0 = owners[0]
            reverses1b = _.clone(owners[1].get('reverses').models); owner1 = owners[1]

            assert.equal(2, owner0.get('reverses').models.length, "Owner0b has 2 reverses.\nExpected: #{2}.\nActual: #{util.inspect(owner0.get('reverses').models.length)}")
            assert.equal(1, owner1.get('reverses').models.length, "Owner1b has 1 reverses.\nExpected: #{1}.\nActual: #{util.inspect(owner1.get('reverses').models.length)}")

            queue.defer checkReverseFn(reverses0b, owner0) # confirm it moved
            assert.equal(null, reverses0[1].get('owner'), "Reverse owner is cleared.\nExpected: #{null}.\nActual: #{util.inspect(reverses0[1].get('owner'))}")
            queue.defer checkReverseFn(reverses1b, owner1) # confirm it moved
            callback()

        queue.await done

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> runTests(options, false, false, callback)
  queue.defer (callback) -> runTests(options, true, false, callback)
  not options.embed or queue.defer (callback) -> runTests(options, false, true, callback)
  not options.embed or queue.defer (callback) -> runTests(options, true, true, callback)
  queue.await callback
