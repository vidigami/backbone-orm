util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
JSONUtils = require '../../../lib/json_utils'

runTests = (options, cache, embed) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 1
  require('../../../lib/cache').configure(if cache then {max: BASE_COUNT} else null) # configure caching

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat)

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    @schema: _.defaults({
      owner: -> ['belongs_to', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Reverse)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    @schema: _.defaults({
      flat: -> ['BelongsTo', Flat, embed: embed]
      reverse: -> ['has_one', Reverse, embed: embed]
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  describe "hasOne (cache: #{cache} embed: #{embed})", ->

    beforeEach (done) ->
      require('../../../lib/cache').reset() # reset cache
      MODELS = {}
      queue = new Queue(1)

      # destroy all
      queue.defer (callback) -> Utils.resetSchemas [Flat, Reverse, Owner], callback

      # create all
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Reverse, BASE_COUNT, {
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

        reverses = MODELS.reverse.slice()
        for owner in MODELS.owner
          do (owner) ->
            owner.set({flat: MODELS.flat.pop(), reverse: reverses.pop()})
            save_queue.defer (callback) -> owner.save {}, Utils.bbCallback callback

        save_queue.await callback

      queue.await done

    # TODO: delay the returning of memory models related models to test lazy loading properly
    it 'Fetches a relation from the store if not present', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        fetched_owner = new Owner({id: test_model.id})
        fetched_owner.fetch Utils.bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")
          delete fetched_owner.attributes.reverse

          reverse = fetched_owner.get 'reverse', (err, reverse) ->
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

    it 'Handles a get query for a belongsTo relation', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        test_model.get 'flat', (err, flat) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(flat, 'found related model')
          if test_model.relationIsEmbedded('flat')
            assert.deepEqual(test_model.toJSON().flat, flat.toJSON(), "Serialized embed. Expected: #{util.inspect(test_model.toJSON().flat)}. Actual: #{util.inspect(flat.toJSON())}")
          else
            assert.deepEqual(test_model.toJSON().flat_id, flat.id, "Serialized id only. Expected: #{test_model.toJSON().flat_id}. Actual: #{flat.id}")
          assert.equal(test_model.get('flat_id'), flat.id, "\nExpected: #{test_model.get('flat_id')}\nActual: #{flat.id}")
          done()

    it 'Can retrieve an id for a hasOne relation via async virtual method', (done) ->
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        test_model.get 'reverse_id', (err, id) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(id, 'found id')
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
            assert.deepEqual(test_model.toJSON().reverse, reverse.toJSON(), "Serialized embed. Expected: #{util.inspect(test_model.toJSON().reverse)}. Actual: #{util.inspect(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_id, 'No reverese_id in owner json')
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
            assert.deepEqual(test_model.toJSON().reverse, reverse.toJSON(), "Serialized embed. Expected: #{util.inspect(test_model.toJSON().reverse)}. Actual: #{util.inspect(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_id, 'No reverese_id in owner json')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'found original model')
            assert.deepEqual(reverse.toJSON().owner_id, owner.id, "Serialized id only. Expected: #{reverse.toJSON().owner_id}. Actual: #{owner.id}")

            if Owner.cache()
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "\nExpected: #{util.inspect(test_model.toJSON())}\nActual: #{util.inspect(owner.toJSON())}")
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

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false, false)
  runTests(options, true, false)
