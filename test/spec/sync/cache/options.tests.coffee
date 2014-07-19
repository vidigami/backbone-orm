assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, Fabricator} = BackboneORM

option_sets = window?.__test__option_sets or require?('../../../option_sets')
parameters = __test__parameters if __test__parameters?
_.each option_sets, exports = (options) ->
  options = _.extend({}, options, parameters) if parameters

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "Cache Options #{options.$parameter_tags or ''}#{options.$tags}", ->
    Flat = null
    before ->
      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

    after (callback) -> Utils.resetSchemas [Flat], (err) -> BackboneORM.model_cache.reset(); callback(err)
    after -> Flat = null

    beforeEach (callback) ->
      BackboneORM.configure({model_cache: {enabled: !!options.cache, max: 100}})

      queue = new Queue(1)
      queue.defer (callback) -> Utils.resetSchemas [Flat], callback
      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback)
      queue.await callback

    describe 'TODO', ->
      it 'TODO', (done) -> done()
