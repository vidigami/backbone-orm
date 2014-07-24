assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "Model.each #{options.$parameter_tags or ''}#{options.$tags}", ->
    Flat = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: BASE_SCHEMA
        sync: SYNC(Flat)

    after (callback) -> Utils.resetSchemas [Flat], callback

    beforeEach (callback) ->
      Utils.resetSchemas [Flat], (err) ->
        return callback(err) if err

        Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, callback

    describe "Queries", ->

      it 'callback for all models', (done) ->
        processed_count = 0

        Flat.each ((model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          callback()
        ), (err) ->
          assert.ifError(err)
          assert.equal(BASE_COUNT, processed_count)
          done()

      it 'callback for all models - eachC (CoffeeScript friendly)', (done) ->
        processed_count = 0

        summary = (err) ->
            assert.ifError(err)
            assert.equal(BASE_COUNT, processed_count)
            done()

        Flat.eachC summary, (model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          callback()

      it 'callback for queried models', (done) ->
        Flat.findOne (err, model) ->
          assert.ifError(err)
          assert.ok(!!model, 'model returned')

          processed_count = 0

          Flat.each {name: model.get('name')},
            ((model, callback) ->
              assert.ok(!!model, 'model returned')
              processed_count++
              callback()
            ),
            (err) ->
              assert.ifError(err)
              assert.equal(1, processed_count)
              done()

      it 'callback for queried models - eachC (CoffeeScript friendly)', (done) ->
        Flat.findOne (err, model) ->
          assert.ifError(err)
          assert.ok(!!model, 'model returned')

          processed_count = 0

          summary = (err) ->
            assert.ifError(err)
            assert.equal(1, processed_count)
            done()

          Flat.eachC {name: model.get('name')}, summary, (model, callback) ->
            assert.ok(!!model, 'model returned')
            processed_count++
            callback()

      it 'callback with limit and offset', (done) ->
        processed_count = 0

        Flat.each {$limit: 10, $offset: BASE_COUNT-3},
          ((model, callback) ->
            assert.ok(!!model, 'model returned')
            processed_count++
            callback()
          ), (err) ->
            assert.ifError(err)
            assert.equal(3, processed_count)
            done()

      it 'callback for queried models with limit and offset', (done) ->
        Flat.findOne (err, model) ->
          assert.ifError(err)
          assert.ok(!!model, 'model returned')

          processed_count = 0

          Flat.each {name: model.get('name'), $limit: 10, $offset: 0},
            ((model, callback) ->
              assert.ok(!!model, 'model returned')
              processed_count++
              callback()
            ),
            (err) ->
              assert.ifError(err)
              assert.equal(1, processed_count)
              done()

    describe "JSON or Models", ->

      it 'Default is models', (done) ->
        processed_count = 0

        Flat.each ((model, callback) ->
          assert.ok(!!model, 'model returned')
          assert.ok(model instanceof Backbone.Model, 'is a model')
          processed_count++
          callback()
        ), (err) ->
          assert.ifError(err)
          assert.equal(BASE_COUNT, processed_count)
          done()

      it 'Non-json is models', (done) ->
        processed_count = 0

        Flat.each {$each: {json: false}}, ((model, callback) ->
          assert.ok(!!model, 'model returned')
          assert.ok(model instanceof Backbone.Model, 'is a model')
          processed_count++
          callback()
        ), (err) ->
          assert.ifError(err)
          assert.equal(BASE_COUNT, processed_count)
          done()

      it 'Can request json', (done) ->
        processed_count = 0

        Flat.each {$each: {json: true}}, ((model, callback) ->
          assert.ok(!!model, 'model returned')
          assert.ok(not (model instanceof Backbone.Model), 'is not a model')
          assert.ok(model.name, 'has a name')
          processed_count++
          callback()
        ), (err) ->
          assert.ifError(err)
          assert.equal(BASE_COUNT, processed_count)
          done()

    describe "Threads", ->
      it 'Default is Infinite threads', (done) ->
        processed_count = 0
        results = []

        Flat.each ((model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          _.delay (-> results.push(processed_count); callback()), 10
        ), (err) ->
          assert.ifError(err)
          assert.equal(BASE_COUNT, processed_count)
          assert.deepEqual(results, _.map([1..BASE_COUNT], -> BASE_COUNT))
          done()

      it 'Can process one at a time', (done) ->
        processed_count = 0
        results = []

        Flat.each {$each: {threads: 1}}, ((model, callback) ->
          assert.ok(!!model, 'model returned')
          processed_count++
          _.delay (-> results.push(processed_count); callback()), 10
        ), (err) ->
          assert.ifError(err)
          assert.equal(BASE_COUNT, processed_count)
          assert.deepEqual(results, [1..BASE_COUNT])
          done()
