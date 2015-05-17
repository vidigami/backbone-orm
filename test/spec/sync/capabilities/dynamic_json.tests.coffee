assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if not (options.sync.capabilities(options.database_url or '').dynamic and options.sync.capabilities(options.database_url or '').json)
  return if options.embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  DATE_INTERVAL_MS = 1000
  START_DATE = new Date()
  END_DATE = new Date(START_DATE.getTime() + (BASE_COUNT - 1) * DATE_INTERVAL_MS)

  describe "Dynamic JSON Functionality #{options.$tags} @dynamic @json", ->
    Model = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Model extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        sync: SYNC(Model)

    after (callback) -> Utils.resetSchemas [Model], callback

    generateFindOne = (key) ->
      it "Handles a #{key} (equal)", (done) ->
        Model.findOne (err, model) ->
          assert.ifError(err)
          assert.ok(!!model, 'found a model')

          (query = {})[key] = model.get(key)
          Model.find query, (err, models) ->
            assert.ifError(err)
            assert.equal(models.length, 1, 'found the expected number of models')
            done()

      it "Handles a #{key} (not equal)", (done) ->
        Model.findOne (err, model) ->
          assert.ifError(err)
          assert.ok(!!model, 'found a model')

          (query = {})[key] = {$ne: model.get(key)}
          Model.find query, (err, models) ->
            assert.ifError(err)
            assert.equal(models.length, BASE_COUNT-1, 'found the expected number of models')
            done()

    beforeEach (callback) ->
      Utils.resetSchemas [Model], (err) ->
        return callback(err) if err

        Fabricator.create Model, BASE_COUNT, {
          name: Fabricator.uniqueId('model_')
          json_number: ((value) -> return -> {value: value()})(Fabricator.increment(0))
          json_string: ((value) -> return -> {value: value()})(Fabricator.uniqueId('string'))
          json_date: ((value) -> return -> {value: value()})(Fabricator.date(START_DATE, DATE_INTERVAL_MS))
          json_nested: ((value) -> return -> {value: {value: value()}})(Fabricator.increment(0))
          json_boolean: {value: true}
        }, callback

    describe 'Find', (done) ->
      generateFindOne('json_number')
      generateFindOne('json_string')
      generateFindOne('json_date')
      generateFindOne('json_nested')

      it "Handles a boolean (equal)", (done) ->
        Model.find {json_boolean: {value: true}}, (err, models) ->
          assert.ifError(err)
          assert.equal(models.length, BASE_COUNT, 'found the expected number of models')
          done()

      it "Handles a boolean (not equal)", (done) ->
        Model.find {json_boolean: {$ne: {value: true}}}, (err, models) ->
          assert.ifError(err)
          assert.equal(models.length, 0, 'found the expected number of models')
          done()
