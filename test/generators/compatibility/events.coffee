util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'

Fabricator = require '../../fabricator'

try BackboneORM = require 'backbone-orm' catch err then BackboneORM = require('../../../backbone-orm')
Queue = BackboneORM.Queue
ModelCache = BackboneORM.CacheSingletons.ModelCache
Utils = BackboneORM.Utils

module.exports = (options, callback) ->
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

  describe "Many to Many (cache: #{options.cache}, query_cache: #{options.query_cache}, embed: #{options.embed})", ->

    before (done) -> return done() unless options.before; options.before([Reverse, Owner], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      relation = Owner.relation('reverses')
      delete relation.virtual
      MODELS = {}

      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure model cache

      # destroy all
      queue.defer (callback) -> Utils.resetSchemas [Reverse, Owner], callback

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
          do (owner) -> save_queue.defer (callback) ->
            owner.save {reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]}, callback

        save_queue.await callback

      queue.await done

  describe "Backbone Events (cache: #{options.cache}, query_cache: #{options.query_cache})", ->

    after (done) -> callback(); done()

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
