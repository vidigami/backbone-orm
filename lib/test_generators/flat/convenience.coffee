# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  MODEL_TYPE = options.model_type
  BEFORE_EACH = options.beforeEach
  MODELS_JSON = null

  assert = require 'assert'
  Queue = require 'queue-async'

  Utils = require '../../../utils'
  adapters = Utils.adapters

  describe 'Convenience Methods', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()

    describe 'count', ->
      it 'Handles a count query', (done) ->
        MODEL_TYPE.count (err, count) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(count, MODELS_JSON.length, 'counted expected number of albums')
          done()

      it 'counts by query', (done) ->
        bob = new MODEL_TYPE({name: 'Bob'})

        queue = new Queue(1)
        queue.defer (callback) -> bob.save {}, adapters.bbCallback(callback)

        queue.defer (callback) ->
          MODEL_TYPE.count {name: 'Bob'}, (err, count) ->
            assert.equal(count, 1, 'found Bob through query')
            callback(err)

        queue.defer (callback) ->
          MODEL_TYPE.count {name: 'Fred'}, (err, count) ->
            assert.equal(count, 0, 'no Fred')
            callback(err)

        queue.defer (callback) ->
          MODEL_TYPE.count {}, (err, count) ->
            assert.ok(count >= 1, 'found Bob through empty query')
            callback(err)

        queue.await done

      it 'counts by query with multiple', (done) ->
        bob = new MODEL_TYPE({name: 'Bob'})
        fred = new MODEL_TYPE({name: 'Fred'})

        queue = new Queue(1)
        queue.defer (callback) -> bob.save {}, adapters.bbCallback(callback)
        queue.defer (callback) -> fred.save {}, adapters.bbCallback(callback)

        queue.defer (callback) ->
          MODEL_TYPE.count {name: 'Bob'}, (err, count) ->
            assert.equal(count, 1, 'found Bob through query')
            callback(err)

        queue.defer (callback) ->
          MODEL_TYPE.count {name: 'Fred'}, (err, count) ->
            assert.equal(count, 1, 'no Fred')
            callback(err)

        queue.defer (callback) ->
          MODEL_TYPE.count {}, (err, count) ->
            assert.ok(count >= 2, 'found Bob and Fred through empty query')
            callback(err)

        queue.defer (callback) ->
          MODEL_TYPE.count (err, count) ->
            assert.ok(count >= 2, 'found Bob and Fred when skipping query')
            callback(err)

        queue.await done

    describe 'all', ->
      it 'Handles an all query', (done) ->
        MODEL_TYPE.all (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, MODELS_JSON.length, 'counted expected number of albums')
          done()
