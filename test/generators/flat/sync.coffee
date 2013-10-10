util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
bbCallback = Utils.bbCallback

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  require('../../../lib/query_cache').configure({enabled: options.query_cache}).reset() # configure query cache
  require('../../../lib/cache').hardReset().configure(if options.cache then {max: 100} else null) # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat)

  describe "Backbone Sync (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      require('../../../lib/query_cache').reset()  # reset cache
      require('../../../lib/cache').reset()
      queue = new Queue(1)

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback)

      queue.await done

#    it 'saves a model and assigns an id', (done) ->
#      bob = new Flat({name: 'Bob'})
#      assert.equal(bob.get('name'), 'Bob', 'name before save is Bob')
#      assert.ok(!bob.id, 'id before save doesn\'t exist')
#
#      queue = new Queue(1)
#      queue.defer (callback) -> bob.save {}, bbCallback(callback)
#
#      queue.defer (callback) ->
#        assert.equal(bob.get('name'), 'Bob', 'name after save is Bob')
#        assert.ok(!!bob.id, 'id after save is assigned')
#        callback()
#
#      queue.await done

    it 'fetches model data', (done) ->
      Flat.findOne (err, model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!model, 'got model')

        new_model = new Flat({id: model.id})
        new_model.fetch bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")
          assert.deepEqual(model.toJSON(), new_model.toJSON(), "\nExpected: #{util.inspect(model.toJSON())}\nActual: #{util.inspect(new_model.toJSON())}")
          done()

#    it 'destroys a model', (done) ->
#      Flat.findOne (err, model) ->
#        assert.ok(!err, "No errors: #{err}")
#        assert.ok(!!model, 'got model')
#        model_id = model.id
#
#        model.destroy bbCallback (err) ->
#          assert.ok(!err, "No errors: #{err}")
#
#          Flat.find model_id, (err, model) ->
#            assert.ok(!err, "No errors: #{err}")
#            assert.ok(!model, "Model not found after destroy")
#            done()
