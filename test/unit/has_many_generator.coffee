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
    many_reverse: -> ['hasOne', HasManyModel, foreign_key: 'reverse_id']
  sync: require('../../memory_backbone_sync')(ReverseModel)

class HasManyModel extends Backbone.Model
  @schema:
    many: -> ['hasMany', FlatModel, foreign_key: 'many_id']
    many_reverse: -> ['hasMany', ReverseModel, foreign_key: 'many_id']
  sync: require('../../memory_backbone_sync')(HasManyModel)

FlatModel.initialize()
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

      destroy_queue.defer (callback) -> FlatModel.destroy callback
      destroy_queue.defer (callback) -> ReverseModel.destroy callback
      destroy_queue.defer (callback) -> HasManyModel.destroy callback

      destroy_queue.await callback

    # create all
    queue.defer (callback) ->
      create_queue = new Queue()

      create_queue.defer (callback) -> Fabricator.create(FlatModel, 2*BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.flat = models; callback(err))
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
          many_model.set({many: [MODELS.flat.pop(), MODELS.flat.pop()]})
          many_model.set({many_reverse: [MODELS.reverse.pop(), MODELS.reverse.pop()]})
          save_queue.defer (callback) -> many_model.save {}, adapters.bbCallback callback

          # TODO: remove when automated
          for related_model in many_model.get('many_reverse').models
            do (related_model) ->
              related_model.set({many_reverse: many_model})
              save_queue.defer (callback) -> related_model.save {}, adapters.bbCallback callback

      save_queue.await callback

    queue.await (err) ->
      # callback(err, _.map(MODELS.many, (test) -> JSONUtils.valueToJSON(test.toJSON())))
      callback(err, _.map(MODELS.many, (test) -> test.toJSON()))

require('../../lib/test_generators/relational/has_many')(test_parameters)
