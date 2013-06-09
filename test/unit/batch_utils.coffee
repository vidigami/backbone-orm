util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Queue = require 'queue-async'

BatchUtils = require '../../batch_utils'
Fabricator = require '../../fabricator'
MockServerModel = require '../../mocks/server_model'

DATE_START = '2013-06-09T08:00:00.000Z'
DATE_STEP_MS = 1000
GENERATE_COUNT = 10

describe 'Batch Utils', ->

  beforeEach (done) ->
    MockServerModel.MODELS = Fabricator.new(MockServerModel, GENERATE_COUNT, {id: Fabricator.uniqueId('id_'), name: Fabricator.uniqueId('name_'), created_at: Fabricator.date(new Date(DATE_START), DATE_STEP_MS), updated_at: Fabricator.date})
    done()

  it 'callback for all models', (done) ->
    processed_count = 0

    queue = new Queue(1)
    queue.defer (callback) -> MockServerModel.count (err, count) ->
      assert.equal(GENERATE_COUNT, count, "Expected number #{GENERATE_COUNT} ready for checking. Actual: #{count}")
      callback(err)

    queue.defer (callback) ->
      BatchUtils.processModels MockServerModel, callback, (model, callback) ->
        assert.ok(!!model, 'model returned')
        processed_count++
        callback()

    queue.await (err) ->
      assert.ok(!err, 'no errors')
      assert.equal(processed_count, GENERATE_COUNT, 'Expected number processed 2')
      done()

