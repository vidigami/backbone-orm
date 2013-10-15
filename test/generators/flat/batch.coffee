util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

QueryCache = require '../../../lib/query_cache/query_cache'
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

  describe "Utils.batch (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

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

    it 'callback for all models (util)', (done) ->
      processed_count = 0

      queue = new Queue(1)
      queue.defer (callback) ->
        Utils.batch Flat, callback, (model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          callback()

      queue.await (err) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(BASE_COUNT, processed_count, "\nExpected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()

    it 'callback for all models (model)', (done) ->
      processed_count = 0

      queue = new Queue(1)
      queue.defer (callback) ->
        Flat.batch callback, (model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          callback()

      queue.await (err) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(BASE_COUNT, processed_count, "\nExpected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()
