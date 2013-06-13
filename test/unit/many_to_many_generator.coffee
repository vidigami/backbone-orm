_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

JSONUtils = require '../../lib/json_utils'
Fabricator = require '../../fabricator'
Utils = require '../../utils'
adapters = Utils.adapters

class ReverseModel extends Backbone.Model
  url: '/reverse_models'
  @schema:
    many_reverse: -> ['hasMany', HasManyModel]
  sync: require('../../memory_backbone_sync')(ReverseModel)

class HasManyModel extends Backbone.Model
  url: '/has_many_models'
  @schema:
    many_reverse: -> ['hasMany', ReverseModel]
  sync: require('../../memory_backbone_sync')(HasManyModel)

ReverseModel.initialize()
HasManyModel.initialize()

BASE_COUNT = 5

test_parameters =
  model_type: HasManyModel
  route: 'mock_models'
  beforeEach: (callback) ->
    MODELS = {}

    queue = new Queue(1)

    # destroy all
    queue.defer (callback) ->
      destroy_queue = new Queue()

      destroy_queue.defer (callback) -> ReverseModel.destroy callback
      destroy_queue.defer (callback) -> HasManyModel.destroy callback

      destroy_queue.await callback

    # create all
    queue.defer (callback) ->
      create_queue = new Queue()

      create_queue.defer (callback) -> Fabricator.create(ReverseModel, 2*BASE_COUNT, {
        name: Fabricator.uniqueId('reverse_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.reverse = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(HasManyModel, BASE_COUNT, {
        name: Fabricator.uniqueId('many_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.many = models; callback(err))

      create_queue.await callback

    # link and save all
    queue.defer (callback) ->
      save_queue = new Queue()

      for many_model in MODELS.many
        do (many_model) ->
          many_model.set({many_reverse: [MODELS.reverse.pop().set({many_reverse: [many_model]}), MODELS.reverse.pop().set({many_reverse: [many_model]})]})
          save_queue.defer (callback) -> many_model.save {}, adapters.bbCallback callback

      save_queue.await callback

    queue.await (err) ->
      callback(err, _.map(MODELS.many, (test) -> test.toJSON()))

require('../../lib/test_generators/relational/many_to_many')(test_parameters)
