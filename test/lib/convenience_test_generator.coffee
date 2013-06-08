assert = require 'assert'
Queue = require 'queue-async'

Album = require '../models/album'
AlbumsFabricator = require '../fabricators/albums'
ALBUM_COUNT = 20

describe 'Syntatic sugar', ->

  beforeEach (done) ->
    queue = new Queue(1)
    queue.defer (callback) -> Album.destroy {}, callback
    queue.defer (callback) -> AlbumsFabricator.create ALBUM_COUNT, callback
    queue.await done

  it 'Handles a count query', (done) ->
    Album.count (err, count) ->
      assert.ok(!err, 'no errors')
      assert.equal(count, ALBUM_COUNT, 'counted expected number of albums')
      done()


  it 'Handles an all query', (done) ->
    Album.all (err, models) ->
      assert.ok(!err, 'no errors')
      assert.equal(models.length, ALBUM_COUNT, 'counted expected number of albums')
      done()

