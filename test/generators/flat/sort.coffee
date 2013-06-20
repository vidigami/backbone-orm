util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../utils'
adapters = Utils.adapters

runTests = (options, cache) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  MODELS_JSON = null

  class Flat extends Backbone.Model
    url: "#{DATABASE_URL}/flats"
    sync: SYNC(Flat, cache)

  describe "Model.sort (cache: #{cache})", ->

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

    it 'Handles a sort by one field query', (done) ->
      SORT_FIELD = 'name'
      Flat.find {$sort: SORT_FIELD}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(Utils.isSorted(models, [SORT_FIELD]))
        done()

    it 'Handles a sort by multiple fields query', (done) ->
      SORT_FIELDS = ['name', 'id']
      Flat.find {$sort: SORT_FIELDS}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(Utils.isSorted(models, SORT_FIELDS))
        done()

    it 'Handles a reverse sort by fields query', (done) ->
      SORT_FIELDS = ['-name', 'id']
      Flat.find {$sort: SORT_FIELDS}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(Utils.isSorted(models, SORT_FIELDS))
        done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
  runTests(options, true)
