util = require 'util'
assert = require 'assert'
_ = require 'underscore'

BatchUtils = require '../../batch_utils'
MockServerModel = require '../../mocks/server_model'

describe 'Batch Utils', ->

  beforeEach: (done) ->
    MockServerModel.MODELS = Fabricator.new(MockServerModel, 10, {
      id: Fabricator.idFn('id_')
      name: Fabricator.idFn('name_')
      created_at: Fabricator.dateString
      updated_at: Fabricator.dateString
    })
    callback(null, _.map(MockServerModel.MODELS, (model) -> model.toJSON()))

  it 'should ensure indexes', (done) ->

    # indexing is async so need to poll
    checkIndexes = ->
      IndexedModel._sync.connection.collection (err, collection) ->
        assert.ok(!err, 'no errors')

        collection.indexExists '_id_', (err, exists) ->
          assert.ok(!err, 'no errors')
          return done() if exists
          _.delay checkIndexes, 50

    checkIndexes()

