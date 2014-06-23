util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require('../../../backbone-orm').Queue

ModelCache = require('../../../backbone-orm').CacheSingletons.ModelCache
Fabricator = require '../../fabricator'

module.exports = (options, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  ModelCache.configure({enabled: !!options.cache, max: 100}).hardReset() # configure model cache

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    schema: BASE_SCHEMA
    sync: SYNC(Flat)

  describe "Cache Options (embed: #{options.embed})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      queue = new Queue(1)

      # reset caches
      queue.defer (callback) -> ModelCache.configure({enabled: !!options.cache, max: 100}).reset(callback) # configure model cache

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date
        updated_at: Fabricator.date
      }, callback)

      queue.await done

    describe 'TODO', ->
      it 'TODO', (done) ->
          done()
