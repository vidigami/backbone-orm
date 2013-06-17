_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../fabricator'
Utils = require '../../utils'
adapters = Utils.adapters

class Reverse extends Backbone.Model
  url: '/reverses'
  @schema:
    owners: -> ['hasMany', Owner]
  sync: require('../../memory_backbone_sync')(Reverse, true)

class Owner extends Backbone.Model
  url: '/owners'
  @schema:
    reverses: -> ['hasMany', Reverse]
  sync: require('../../memory_backbone_sync')(Owner, true)

BASE_COUNT = 3

test_parameters =
  model_type: Owner
  route: 'mock_models'
  beforeEach: (callback) ->
    MODELS = {}

    queue = new Queue(1)

    # destroy all
    queue.defer (callback) ->
      destroy_queue = new Queue()

      destroy_queue.defer (callback) -> Reverse.destroy callback
      destroy_queue.defer (callback) -> Owner.destroy callback

      destroy_queue.await callback

    # create all
    queue.defer (callback) ->
      create_queue = new Queue()

      create_queue.defer (callback) -> Fabricator.create(Reverse, 2*BASE_COUNT, {
        name: Fabricator.uniqueId('reverses_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.reverse = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
        name: Fabricator.uniqueId('owners_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.owner = models; callback(err))

      create_queue.await callback

    # link and save all
    queue.defer (callback) ->
      save_queue = new Queue()

      for owner in MODELS.owner
        do (owner) ->
          owner.set({reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]})
          save_queue.defer (callback) -> owner.save {}, adapters.bbCallback callback

      save_queue.await callback

    queue.await (err) ->
      callback(err, _.map(MODELS.owner, (test) -> test.toJSON()))

require('../../lib/test_generators/relational/many_to_many')(test_parameters)
