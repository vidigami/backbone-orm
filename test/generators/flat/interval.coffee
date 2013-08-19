util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
moment = require 'moment'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'

runTests = (options, cache, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 50
  require('../../../lib/cache').configure(if cache then {max: 100} else null) # configure caching

  DATE_START = moment.utc('2013-06-09T08:00:00.000Z').toDate()
  DATE_STEP_MS = 1000

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    sync: SYNC(Flat)

  describe "Utils.interval (cache: #{cache})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      require('../../../lib/cache').reset() # reset cache
      queue = new Queue(1)

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date(DATE_START, DATE_STEP_MS)
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
      interval_count = 0

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.interval {
          key: 'created_at'
          range: {$gte: DATE_START}
          type: 'milliseconds'
          length: 2*DATE_STEP_MS
        }, callback, (query, info, callback) ->
          assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")
          interval_count++
          Flat.batch query, {}, callback, (model, callback) ->
            processed_count++
            callback()

      queue.await (err) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()

    it 'callback for all models (model and no range)', (done) ->
      processed_count = 0
      interval_count = 0

      queue = new Queue(1)

      queue.defer (callback) ->
        Flat.interval {
          key: 'created_at'
          type: 'milliseconds'
          length: 2*DATE_STEP_MS
        }, callback, (query, info, callback) ->
          assert.equal(interval_count, info.index, "Has correct index. Expected: #{interval_count}. Actual: #{info.index}")
          interval_count++
          Flat.batch query, {}, callback, (model, callback) ->
            processed_count++
            callback()

      queue.await (err) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(BASE_COUNT/2, interval_count, "Interval count. Expected: #{BASE_COUNT/2}\nActual: #{interval_count}")
        assert.equal(BASE_COUNT, processed_count, "Processed count. Expected: #{BASE_COUNT}\nActual: #{processed_count}")
        done()



# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> runTests(options, false, callback)
  queue.defer (callback) -> runTests(options, true, callback)
  queue.await callback
