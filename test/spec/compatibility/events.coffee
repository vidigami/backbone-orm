assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM or require?('backbone-orm')
_ = BackboneORM._; Backbone = BackboneORM.Backbone
Queue = BackboneORM.Queue
ModelCache = BackboneORM.CacheSingletons.ModelCache
Utils = BackboneORM.Utils
Fabricator = BackboneORM.Fabricator

_.each (require '../../option_sets'), module.exports = (options) ->
  return if options.embed or options.query_cache
  options = _.extend({}, options, test_parameters) if test_parameters?

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

  OMIT_KEYS = ['owner_id', '_rev', 'created_at', 'updated_at']

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    schema: _.defaults({
      owners: -> ['hasMany', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Reverse)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    schema: _.defaults({
      reverses: -> ['hasMany', Reverse]
    }, BASE_SCHEMA)
    sync: SYNC(Owner)

  describe "Backbone Events #{options.$tags}", ->
    describe 'Triggering', ->

      # https://github.com/vidigami/backbone-mongo/issues/4
      it 'should trigger by all permutations', (done) ->
        attribute_change_count = 0
        reset_change_count = 0

        class ManyModel extends Backbone.Model
          urlRoot: "#{DATABASE_URL}/reverses"
          schema: _.defaults({
            owners: -> ['hasMany', MainModel]
          }, BASE_SCHEMA)
          sync: SYNC(ManyModel)

        class MainModel extends Backbone.Model
          urlRoot: "#{DATABASE_URL}/owners"
          schema: _.defaults({
            reverses: -> ['hasMany', ManyModel]
          }, BASE_SCHEMA)
          sync: SYNC(MainModel)

          initialize: ->
            super
            @on 'change:reverses', -> attribute_change_count++
            @get('reverses').on 'reset', -> reset_change_count++

        assert.equal(attribute_change_count, 0)
        assert.equal(reset_change_count, 0)

        main = new MainModel()
        many = new ManyModel({foo: 'bar'})
        assert.equal(attribute_change_count, 0)
        assert.equal(reset_change_count, 0)

        main.set('reverses', [many]);
        assert.equal(attribute_change_count, 0)
        assert.equal(reset_change_count, 1)

        manyCollection = main.get('reverses')
        manyCollection.push(many)
        main.set('reverses', manyCollection)
        assert.equal(attribute_change_count, 0)
        assert.equal(reset_change_count, 2)

        main.set('reverses', [many])
        assert.equal(attribute_change_count, 0)
        assert.equal(reset_change_count, 3)

        done()
