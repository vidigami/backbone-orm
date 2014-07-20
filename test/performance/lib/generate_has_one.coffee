module.exports = (options, callback) ->
  {Backbone, Fabricator} = BackboneORM = options.BackboneORM

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = options.count

  BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: BASE_SCHEMA
    sync: SYNC(Flat)

  Fabricator.create Flat, BASE_COUNT, {
    name: Fabricator.uniqueId('flat_')
    created_at: Fabricator.date
  }, (err, models) ->
    return callback(err) if err
    callback(null, {Flat})
