Queue = require 'queue-async'

module.exports = (options, callback) ->
  {Backbone, Fabricator} = BackboneORM = options.BackboneORM

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = options.count
  MODELS = {}

  BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: BASE_SCHEMA
    sync: SYNC(Flat)

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    schema: _.defaults({
      owner: -> ['belongsTo', Owner]
      another_owner: -> ['belongsTo', Owner, as: 'more_reverses']
    }, BASE_SCHEMA)
    sync: SYNC(Reverse)

  class ForeignReverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/foreign_reverses"
    schema: _.defaults({
      owner: -> ['belongsTo', Owner, foreign_key: 'ownerish_id']
    }, BASE_SCHEMA)
    sync: SYNC(ForeignReverse)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    schema: _.defaults({
      flats: -> ['hasMany', Flat]
      reverses: -> ['hasMany', Reverse]
      more_reverses: -> ['hasMany', Reverse, as: 'another_owner']
      foreign_reverses: -> ['hasMany', ForeignReverse]
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  queue = new Queue(1)
  queue.defer (callback) ->
    create_queue = new Queue()

    create_queue.defer (callback) -> Fabricator.create Flat, 2*BASE_COUNT, {
      name: Fabricator.uniqueId('flat_')
      created_at: Fabricator.date
    }, (err, models) -> MODELS.flat = models; callback(err)
    create_queue.defer (callback) -> Fabricator.create Reverse, 2*BASE_COUNT, {
      name: Fabricator.uniqueId('reverse_')
      created_at: Fabricator.date
    }, (err, models) -> MODELS.reverse = models; callback(err)
    create_queue.defer (callback) -> Fabricator.create Reverse, 2*BASE_COUNT, {
      name: Fabricator.uniqueId('reverse_')
      created_at: Fabricator.date
    }, (err, models) -> MODELS.more_reverse = models; callback(err)
    create_queue.defer (callback) -> Fabricator.create ForeignReverse, BASE_COUNT, {
      name: Fabricator.uniqueId('foreign_reverse_')
      created_at: Fabricator.date
    }, (err, models) -> MODELS.foreign_reverse = models; callback(err)
    create_queue.defer (callback) -> Fabricator.create Owner, BASE_COUNT, {
      name: Fabricator.uniqueId('owner_')
      created_at: Fabricator.date
    }, (err, models) -> MODELS.owner = models; callback(err)

    create_queue.await callback

  # link and save all
  queue.defer (callback) ->
    save_queue = new Queue()

    link_tasks = []
    for owner in MODELS.owner
      link_task =
        owner: owner
        values:
          flats: [MODELS.flat.pop(), MODELS.flat.pop()]
          reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]
          more_reverses: [MODELS.more_reverse.pop(), MODELS.more_reverse.pop()]
          foreign_reverses: [MODELS.foreign_reverse.pop()]
      link_tasks.push(link_task)

    for link_task in link_tasks then do (link_task) -> save_queue.defer (callback) ->
      link_task.owner.set(link_task.values)
      link_task.owner.save callback

    save_queue.await callback

  queue.await (err) ->
    return callback(err) if err
    callback(null, {Flat, Reverse, ForeignReverse, Owner})
