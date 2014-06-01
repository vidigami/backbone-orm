util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require '../../../lib/queue'

ModelCache = require('../../../lib/cache/singletons').ModelCache

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure({enabled: !!options.cache, max: 100}) # configure caching

  class FirstModel extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/firsts"
    schema: _.defaults({
      seconds: -> ['hasMany', SecondModel]
    }, BASE_SCHEMA)
    sync: SYNC(FirstModel)

  class SecondModel extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/seconds"
    schema: _.defaults({
      firsts: -> ['hasMany', FirstModel]
    }, BASE_SCHEMA)
    sync: SYNC(SecondModel)

  first_id = null
  second_ids = []
  describe 'Join Table Functionality', ->

    before (done) -> return done() unless options.before; options.before([FirstModel, SecondModel], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      queue = new Queue(1)
      queue.defer (callback) -> FirstModel.resetSchema(callback)
      queue.defer (callback) -> SecondModel.resetSchema(callback)
      queue.defer (callback) ->
        models = []
        models.push new FirstModel()
        models.push new FirstModel()
        models.push new SecondModel({firsts: [models[0]]})
        models.push new SecondModel({firsts: [models[1]]})

        model_queue = new Queue(1)
        for model in models
          do (model) -> model_queue.defer (callback) ->
            model.save callback

        model_queue.await (err) ->
          first_id = models[1].id
          second_ids.push(models[i].id) for i in [2..3]
          callback()

      queue.await done

    ######################################
    # Join Table
    ######################################

    describe 'scope by second model', ->
      it 'it should return only requested model', (done) ->

        # console.log 'First Model ID', first_id, 'Second Model IDs', second_ids
        FirstModel.find {id: first_id, 'seconds.id': {$in: second_ids}}, (err, firsts) ->
          assert.ok(!err, "No errors: #{err}")
          # console.log 'Returned First Model IDs', _.pluck(firsts, 'id')
          assert.ok(firsts.length is 1, "Length should be 1: #{firsts.length}")
          done()
