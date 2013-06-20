util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../utils'
adapters = Utils.adapters

runTests = (options, cache, embed) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 1

  class Flat extends Backbone.Model
    url: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat, cache)

  class Reverse extends Backbone.Model
    url: "#{DATABASE_URL}/reverses"
    @schema: _.defaults(BASE_SCHEMA, {
      owner: -> ['belongsTo', Owner]
    })
    sync: SYNC(Reverse, cache)

  class Owner extends Backbone.Model
    url: "#{DATABASE_URL}/owners"
    @schema: _.defaults(BASE_SCHEMA, {
      flats: -> ['hasMany', Flat]
      reverses: -> ['hasMany', Reverse]
    })
    sync: SYNC(Owner, cache)

  describe "hasMany (cache: #{cache} embed: #{embed})", ->

    beforeEach (done) ->
      MODELS = {}

      queue = new Queue(1)

      # destroy all
      queue.defer (callback) ->
        destroy_queue = new Queue()

        destroy_queue.defer (callback) -> Flat.destroy callback
        destroy_queue.defer (callback) -> Reverse.destroy callback
        destroy_queue.defer (callback) -> Owner.destroy callback

        destroy_queue.await callback

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
        create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owner_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err))

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        for owner in MODELS.owner
          do (owner) ->
            owner.set({
              flats: [flat1 = MODELS.flat.pop(), flat2 = MODELS.flat.pop()]
              reverses: [reverse1 = MODELS.reverse.pop(), reverse2 = MODELS.reverse.pop()]
            })
            save_queue.defer (callback) -> owner.save {}, adapters.bbCallback callback
            save_queue.defer (callback) -> flat1.save {}, adapters.bbCallback callback
            save_queue.defer (callback) -> flat2.save {}, adapters.bbCallback callback
            save_queue.defer (callback) -> reverse1.save {}, adapters.bbCallback callback
            save_queue.defer (callback) -> reverse2.save {}, adapters.bbCallback callback

        save_queue.await callback

      queue.await done

    it 'Handles a get query for a hasMany relation', (done) ->
      Owner.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'flats', (err, flats) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, flats.length, "Expected: #{2}. Actual: #{flats.length}")
          if test_model.relationIsEmbedded('flats')
            assert.deepEqual(test_model.toJSON().flats[0], flats[0].toJSON(), "Serialized embedded. Expected: #{test_model.toJSON().flats[0]}. Actual: #{flats[0].toJSON()}")
          done()

    it 'Handles an async get query for ids', (done) ->
      Owner.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'flat_ids', (err, ids) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(2, ids.length, "Expected count: #{2}. Actual: #{ids.length}")
          done()

    it 'Handles a synchronous get query for ids after the relations are loaded', (done) ->
      Owner.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'flats', (err, flats) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(test_model.get('flat_ids').length, flats.length, "Expected count: #{test_model.get('flat_ids').length}. Actual: #{flats.length}")
          assert.deepEqual(test_model.get('flat_ids')[0], flats[0].get('id'), "Serialized id only. Expected: #{test_model.get('flat_ids')[0]}. Actual: #{flats[0].get('id')}")
          done()

    it 'Handles a get query for a hasMany and belongsTo two sided relation', (done) ->
      Owner.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses, 'found models')
          assert.equal(2, reverses.length, "Expected: #{2}. Actual: #{reverses.length}")

          if test_model.relationIsEmbedded('reverses')
            assert.deepEqual(test_model.toJSON().reverses[0], reverses[0].toJSON(), 'Serialized embedded')
          assert.deepEqual(test_model.get('reverse_ids')[0], reverses[0].get('id'), 'serialized id only')
          reverse = reverses[0]

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'found owner models')
            if reverse.relationIsEmbedded('owner')
              assert.deepEqual(reverse.toJSON().owner_id, owner.get('id'), "Serialized embedded. Expected: #{util.inspect(reverse.toJSON().owner_id)}. Actual: #{util.inspect(owner.get('id'))}")
            assert.deepEqual(reverse.get('owner_id'), owner.get('id'), "Serialized id only. Expected: #{reverse.toJSON().owner}. Actual: #{owner.get('id')}")

            if Owner.cache()
              assert.deepEqual(JSON.stringify(test_model.toJSON()), JSON.stringify(owner.toJSON()), "\nExpected: #{util.inspect(test_model.toJSON())}\nActual: #{util.inspect(test_model.toJSON())}")
            else
              assert.equal(test_model.get('id'), owner.get('id'), "\nExpected: #{test_model.get('id')}\nActual: #{owner.get('id')}")
            done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false, false)
  runTests(options, true, false)
  runTests(options, false, true) if options.embed
  runTests(options, true, true) if options.embed
