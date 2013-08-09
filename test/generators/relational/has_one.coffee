util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
JSONUtils = require '../../../lib/json_utils'

runTests = (options, cache, embed, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 2
  require('../../../lib/cache').configure(if cache then {max: 100} else null) # configure caching

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: _.defaults({
      owner: -> ['hasOne', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Flat)

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    @schema: _.defaults({
      owner: -> ['belongsTo', Owner]
      owner_as: -> ['belongsTo', Owner, as: 'reverse_as']
    }, BASE_SCHEMA)
    sync: SYNC(Reverse)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    @schema: _.defaults({
      flat: -> ['belongsTo', Flat, embed: embed]
      reverse: -> ['hasOne', Reverse, embed: embed]
      reverse_as: -> ['hasOne', Reverse, as: 'owner_as', embed: embed]
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  describe "hasOne (cache: #{cache} embed: #{embed})", ->

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
        reversed_reverse = _.clone(MODELS.reverse).reverse()

        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.set({flat: MODELS.flat.pop(), reverse: MODELS.reverse.pop(), reverse_as: reversed_reverse.pop()})
            owner.save {}, Utils.bbCallback callback

        save_queue.await callback

      queue.await done

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
            assert.deepEqual(test_model.toJSON().reverse, reverse.toJSON(), "Serialized embed. Expected: #{util.inspect(test_model.toJSON().reverse)}. Actual: #{util.inspect(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_id, 'No reverse_id in owner json')

          reverse.get 'owner', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'found original model')
            assert.deepEqual(reverse.toJSON().owner_id, owner.id, "Serialized id only. Expected: #{reverse.toJSON().owner_id}. Actual: #{owner.id}")

            if Owner.cache
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
            assert.deepEqual(test_model.toJSON().reverse_as, reverse.toJSON(), "Serialized embed. Expected: #{util.inspect(test_model.toJSON().reverse)}. Actual: #{util.inspect(reverse.toJSON())}")
          assert.ok(!test_model.toJSON().reverse_as_id, 'No reverse_as_id in owner json')

          reverse.get 'owner_as', (err, owner) ->
            assert.ok(!err, "No errors: #{err}")
            assert.ok(owner, 'found original model')
            assert.deepEqual(reverse.toJSON().owner_as_id, owner.id, "Serialized id only. Expected: #{reverse.toJSON().owner_as_id}. Actual: #{owner.id}")

            if Owner.cache
              assert.deepEqual(test_model.toJSON(), owner.toJSON(), "\nExpected: #{util.inspect(test_model.toJSON())}\nActual: #{util.inspect(owner.toJSON())}")
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

    it 'Can query on a related (belongsTo) model propery', (done) ->
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
