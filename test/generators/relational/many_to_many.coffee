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

  class Reverse extends Backbone.Model
    url: "#{DATABASE_URL}/reverses"
    @schema: _.defaults({
      owners: -> ['hasMany', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Reverse, cache)

  class Owner extends Backbone.Model
    url: "#{DATABASE_URL}/owners"
    @schema: _.defaults({
      reverses: -> ['hasMany', Reverse]
    }, BASE_SCHEMA)
    sync: SYNC(Owner, cache)

  describe "Many to Many (cache: #{cache} embed: #{embed})", ->

    beforeEach (done) ->
      MODELS = {}

      queue = new Queue(1)

      # destroy all
      queue.defer (callback) ->
        destroy_queue = new Queue()

        destroy_queue.defer (callback) -> Reverse.destroy callback
        destroy_queue.defer (callback) -> Owner.destroy callback

        destroy_queue.await callback

      # create all
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create(Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverses_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owners_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err))

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        for owner in MODELS.owner
          do (owner) ->
            owner.set({reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]})
            save_queue.defer (callback) -> owner.save {}, adapters.bbCallback callback

        save_queue.await callback

      queue.await done

    it 'Handles a get query for a hasMany and hasMany two sided relation', (done) ->
      Owner.find {$one: true}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        test_model.get 'reverses', (err, reverses) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(reverses.length, 'found related reverses')
          if test_model.relationIsEmbedded('reverses')
            assert.deepEqual(test_model.toJSON().reverses[0], reverses[0].toJSON(), "Serialized embedded. Expected: #{test_model.toJSON().reverses}. Actual: #{reverses[0].toJSON()}")
          else
            assert.deepEqual(test_model.get('reverse_ids')[0], reverses[0].get('id'), "Serialized id only. Expected: #{test_model.get('reverse_ids')[0]}. Actual: #{reverses[0].get('id')}")
          reverse = reverses[0]

          reverse.get 'owners', (err, owners) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owners.length, 'found related models')

            owner = _.find(owners, (test) -> test_model.get('id') is test.get('id'))
            owner_index = _.indexOf(owners, owner)
            if reverse.relationIsEmbedded('owners')
              assert.deepEqual(reverse.toJSON().owner_ids[owner_index], owner.get('id'), "Serialized embedded. Expected: #{reverse.toJSON().owner_ids[owner_index]}. Actual: #{owner.get('id')}")
            else
              assert.deepEqual(reverse.get('owner_ids')[owner_index], owner.get('id'), "Serialized id only. Expected: #{reverse.get('owner_ids')[owner_index]}. Actual: #{owner.get('id')}")
            assert.ok(!!owner, 'found owner')

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
