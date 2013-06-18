_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../fabricator'
Utils = require '../../utils'
adapters = Utils.adapters

class Flat extends Backbone.Model
  url: '/flats'
  sync: require('../../memory_backbone_sync')(Flat, true)

class Reverse extends Backbone.Model
  url: '/reverses'
  @schema:
    owner: -> ['hasOne', Owner, foreign_key: 'reverse_id']
  sync: require('../../memory_backbone_sync')(Reverse, true)

class Owner extends Backbone.Model
  url: '/owners'
  @schema:
    flats: -> ['hasMany', Flat, foreign_key: 'owner_id', embed: true]
    reverses: -> ['hasMany', Reverse, foreign_key: 'owner_id', embed: true]
  sync: require('../../memory_backbone_sync')(Owner, true)

BASE_COUNT = 3

test_parameters =
  model_type: Owner
  route: 'mocks'
  beforeEach: (callback) ->
    MODELS = {}

    queue = new Queue(1)

    # destroy all
    queue.defer (callback) ->
      destroy_queue = new Queue()

      destroy_queue.defer (callback) -> Flat.destroy callback
      destroy_queue.defer (callback) -> Reverse.destroy callback
      destroy_queue.defer (callback) -> Owner.destroy callback

      destroy_queue.await callback

    # create all
    queue.defer (callback) ->
      create_queue = new Queue()

      create_queue.defer (callback) -> Fabricator.create(Flat, 2*BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.flat = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(Reverse, 2*BASE_COUNT, {
        name: Fabricator.uniqueId('reverse_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.reverse = models; callback(err))
      create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
        name: Fabricator.uniqueId('owner_')
        created_at: Fabricator.date
      }, (err, models) -> MODELS.owner = models; callback(err))

      create_queue.await callback

    # link and save all
    queue.defer (callback) ->
      save_queue = new Queue()

      for owner in MODELS.owner
        do (owner) ->
          owner.set({
            flats: [MODELS.flat.pop(), MODELS.flat.pop()]
            reverses: [reverse1 = MODELS.reverse.pop(), reverse2 = MODELS.reverse.pop()]
          })
          save_queue.defer (callback) -> owner.save {}, adapters.bbCallback callback

      save_queue.await callback

    queue.await (err) ->
      callback(err, _.map(MODELS.owner, (test) -> test.toJSON()))

require('../../lib/test_generators/relational/has_many_embedded')(test_parameters)
