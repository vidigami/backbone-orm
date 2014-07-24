assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed and not options.sync.capabilities(options.database_url or '').embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  first_id = null
  second_ids = []
  describe "Join Table Functionality #{options.$parameter_tags or ''}#{options.$tags}", ->
    FirstModel = SecondModel = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

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

    after (callback) -> Utils.resetSchemas [FirstModel, SecondModel], callback

    beforeEach (callback) ->
      queue = new Queue(1)
      queue.defer (callback) -> Utils.resetSchemas [FirstModel, SecondModel], callback
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

      queue.await callback

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
