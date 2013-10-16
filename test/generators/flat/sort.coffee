util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

QueryCache = require '../../../lib/query_cache'
Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  require('../../../lib/cache').hardReset().configure(if options.cache then {max: 100} else null) # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat)

  describe "Model.sort (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      require('../../../lib/cache').reset()
      queue = new Queue(1)

      # reset query cache
      queue.defer (callback) -> QueryCache.configure({enabled: true, verbose: false}).reset(callback) # configure query cache

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback)

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
