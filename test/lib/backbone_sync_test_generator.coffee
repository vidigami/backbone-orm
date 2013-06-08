assert = require 'assert'
Queue = require 'queue-async'

Backbone = require 'backbone'

Helpers = require '../lib/helpers'
adapters = Helpers.adapters

Album = require '../models/album'

describe 'BackboneSync', ->

  beforeEach (done) ->
    Thing.destroy(done)

  describe 'save a model', ->
    it 'assign an id', (done) ->
      bob = new Thing({name: 'Bob'})
      assert.equal(bob.get('name'), 'Bob', 'name before save is Bob')
      assert.ok(!bob.get('id'), 'id before save doesn\'t exist')

      queue = new Queue(1)
      queue.defer (callback) -> bob.save {}, adapters.bbCallback(callback)

      queue.defer (callback) ->
        assert.equal(bob.get('name'), 'Bob', 'name after save is Bob')
        assert.ok(!!bob.get('id'), 'id after save is assigned')
        callback()

      queue.await done

  describe 'counts models', ->
    it 'counts by query', (done) ->
      bob = new Thing({name: 'Bob'})

      queue = new Queue(1)
      queue.defer (callback) -> bob.save {}, adapters.bbCallback(callback)

      queue.defer (callback) ->
        Thing.count {name: 'Bob'}, (err, count) ->
          assert.equal(count, 1, 'found Bob through query')
          callback(err)

      queue.defer (callback) ->
        Thing.count {name: 'Fred'}, (err, count) ->
          assert.equal(count, 0, 'no Fred')
          callback(err)

      queue.defer (callback) ->
        Thing.count {}, (err, count) ->
          assert.equal(count, 1, 'found Bob through empty query')
          callback(err)

      queue.await done

    it 'counts by query with multiple', (done) ->
      bob = new Thing({name: 'Bob'})
      fred = new Thing({name: 'Fred'})

      queue = new Queue(1)
      queue.defer (callback) -> bob.save {}, adapters.bbCallback(callback)
      queue.defer (callback) -> fred.save {}, adapters.bbCallback(callback)

      queue.defer (callback) ->
        Thing.count {name: 'Bob'}, (err, count) ->
          assert.equal(count, 1, 'found Bob through query')
          callback(err)

      queue.defer (callback) ->
        Thing.count {name: 'Fred'}, (err, count) ->
          assert.equal(count, 1, 'no Fred')
          callback(err)

      queue.defer (callback) ->
        Thing.count {}, (err, count) ->
          assert.equal(count, 2, 'found Bob and Fred through empty query')
          callback(err)

      queue.defer (callback) ->
        Thing.count (err, count) ->
          assert.equal(count, 2, 'found Bob and Fred when skipping query')
          callback(err)

      queue.await done

  # sync: new BackboneSync({database_config: require('../config/database'), collection: 'bobs', model: Thing, manual_id: true, indices: {id: 1}})
  # TODO: describe 'use a manual id', ->
  #   it 'assign an id', (done) ->

  # TODO: describe 'add an index', ->
