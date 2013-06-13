util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

JSONUtils = require '../../lib/json_utils'
Fabricator = require '../../fabricator'
Utils = require '../../utils'
adapters = Utils.adapters

class FlatModel extends Backbone.Model
  sync: require('../../memory_backbone_sync')(FlatModel)

class ReverseModel extends Backbone.Model
  @schema:
    one_reverse: -> ['hasOne', HasOneModel]
  sync: require('../../memory_backbone_sync')(ReverseModel)

class HasOneModel extends Backbone.Model
  @schema:
    one: -> ['hasOne', FlatModel] #, reverse: true]
    one_reverse: -> ['hasOne', ReverseModel, reverse: true]
  sync: require('../../memory_backbone_sync')(HasOneModel)

FlatModel.initialize()
ReverseModel.initialize()
HasOneModel.initialize()

BASE_COUNT = 5

test_parameters =
  model_type: HasOneModel
  route: 'mock_models'
  beforeEach: (callback) ->
    MODELS = {}

    queue = new Queue(1)

    # destroy all
    queue.defer (callback) ->
      destroy_queue = new Queue()

      destroy_queue.defer (callback) -> FlatModel.destroy callback
      destroy_queue.defer (callback) -> ReverseModel.destroy callback
      destroy_queue.defer (callback) -> HasOneModel.destroy callback

      destroy_queue.await callback

    # create all
    queue.defer (callback) ->
      create_queue = new Queue()

      create_queue.defer (callback) -> Fabricator.create(FlatModel, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.flat = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(ReverseModel, BASE_COUNT, {
        name: Fabricator.uniqueId('reverse_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.reverse = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(HasOneModel, BASE_COUNT, {
        name: Fabricator.uniqueId('one_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.one = models; callback(err))

      create_queue.await callback

    # link and save all
    queue.defer (callback) ->
      save_queue = new Queue()

      for one_model in MODELS.one
        do (one_model) ->
          one_model.set({one: MODELS.flat.pop(), one_reverse: reverse_model = MODELS.reverse.pop()})
          save_queue.defer (callback) -> one_model.save {}, adapters.bbCallback callback

          # TODO: remove when automated
          reverse_model.set({one_reverse: one_model})
          save_queue.defer (callback) -> reverse_model.save {}, adapters.bbCallback callback

      save_queue.await callback

    queue.await (err) ->
      callback(err, _.map(MODELS.one, (test) -> JSONUtils.valueToJSON(test.toJSON())))

require('../../lib/test_generators/relational/has_one')(test_parameters)
