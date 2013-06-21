util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
adapters = Utils.adapters

runTests = (options, cache) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 1
  MODELS_JSON = null

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat, cache)

  describe "Backbone Sync (cache: #{cache})", ->

    beforeEach (done) ->
      queue = new Queue(1)

      queue.defer (callback) -> Flat.destroy callback

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, (err, models) ->
        return callback(err) if err
        MODELS_JSON = _.map(models, (test) -> test.toJSON())
        callback()
      )

      queue.await done

    describe 'save a model', ->
      it 'assign an id', (done) ->
        bob = new Flat({name: 'Bob'})
        assert.equal(bob.get('name'), 'Bob', 'name before save is Bob')
        assert.ok(!bob.get('id'), 'id before save doesn\'t exist')

        queue = new Queue(1)
        queue.defer (callback) -> bob.save {}, adapters.bbCallback(callback)

        queue.defer (callback) ->
          assert.equal(bob.get('name'), 'Bob', 'name after save is Bob')
          assert.ok(!!bob.get('id'), 'id after save is assigned')
          callback()

        queue.await done

    describe 'fetch model', ->
      it 'fetches data', (done) ->
        Flat.find {$one: true}, (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(!!model, 'got model')

          new_model = new Flat({id: model.get('id')})
          new_model.fetch adapters.bbCallback (err) ->
            assert.ok(!err, "No errors: #{err}")
            assert.deepEqual(model.toJSON(), new_model.toJSON(), "\nExpected: #{util.inspect(model.toJSON())}\nActual: #{util.inspect(new_model.toJSON())}")
            done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
  runTests(options, true)
