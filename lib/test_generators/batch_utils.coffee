# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  MODEL_TYPE = options.model_type
  BEFORE_EACH = options.beforeEach
  MODELS_JSON = null

  util = require 'util'
  assert = require 'assert'
  _ = require 'underscore'
  Queue = require 'queue-async'

  BatchUtils = require '../../batch_utils'

  DATE_START = '2013-06-09T08:00:00.000Z'
  DATE_STEP_MS = 1000

  describe 'Batch Utils', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    it 'callback for all models', (done) ->
      processed_count = 0

      queue = new Queue(1)
      queue.defer (callback) ->
        BatchUtils.processModels MODEL_TYPE, callback, (model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          callback()

      queue.await (err) ->
        assert.ok(!err, 'no errors')
        assert.equal(processed_count, MODEL_TYPE.length, 'Expected number processed')
        done()

