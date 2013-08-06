util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'
moment = require 'moment'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
bbCallback = Utils.bbCallback

runTests = (options, cache, callback) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5
  require('../../../lib/cache').configure(if cache then {max: 100} else null) # configure caching

  DATE_INTERVAL_MS = 1000
  START_DATE = new Date()
  END_DATE = moment(START_DATE).add('milliseconds', (BASE_COUNT - 1) * DATE_INTERVAL_MS).toDate()

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: _.defaults({
      boolean: 'Boolean'
    }, BASE_SCHEMA)
    sync: SYNC(Flat)

  describe "Model.find (cache: #{cache})", ->

    before (done) -> return done() unless options.before; options.before([Flat], done)
    after (done) -> callback(); done()
    beforeEach (done) ->
      require('../../../lib/cache').reset() # reset cache
      queue = new Queue(1)

      queue.defer (callback) -> Flat.resetSchema(callback)

      queue.defer (callback) -> Fabricator.create(Flat, BASE_COUNT, {
        name: Fabricator.uniqueId('flat_')
        created_at: Fabricator.date(START_DATE, DATE_INTERVAL_MS)
        updated_at: Fabricator.date
        boolean: true
      }, callback)

      queue.await done

    it 'Handles a limit query', (done) ->
      Flat.find {$limit: 3}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(models.length, 3, 'found the right number of models')
        done()

    it 'Handles a find id query', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        Flat.find test_model.id, (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(model, 'gets a model')
          assert.equal(model.id, test_model.id, 'model has the correct id')
          done()

    it 'Handles a findOne query by id', (done) ->
      Flat.findOne {$sort: '-name'}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        Flat.findOne test_model.id, (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(model, 'gets a model')
          assert.equal(model.id, test_model.id, 'model has the correct id')
          done()


    it 'Handles another find id query', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        Flat.find test_model.id, (err, model) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(model, 'gets a model')
          assert.equal(model.id, test_model.id, 'model has the correct id')
          done()


    it 'Handles a find by query id', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        Flat.find {id: test_model.id}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, 1, 'finds the model')
          assert.equal(models[0].id, test_model.id, 'model has the correct id')
          done()


    it 'Handles a name find query', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        Flat.find {name: test_model.get('name')}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models.length, 'gets models')
          for model in models
            assert.equal(model.get('name'), test_model.get('name'), 'model has the correct name')
          done()

    it 'Handles a find $in query', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        $in = ['random_string', 'some_9', test_model.get('name')]

        Flat.find {name: {$in: $in}}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.ok(models.length, 'finds one model')
          for model in models
            assert.equal(test_model.get('name'), model.get('name'), "Names match:\nExpected: #{test_model.get('name')}, Actual: #{model.get('name')}")
          done()

    it 'Find can retrieve a boolean as a boolean', (done) ->
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        assert.equal(typeof test_model.get('boolean'), 'boolean', "Is a boolean:\nExpected: 'boolean', Actual: #{typeof test_model.get('boolean')}")
        assert.deepEqual(true, test_model.get('boolean'), "Bool matches:\nExpected: #{true}, Actual: #{test_model.get('boolean')}")
        done()

    it 'Handles null finds', (done) ->
      NAME = 'Bob'

      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!test_model, 'test model found')
        test_model.save {name: null}, bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")

          Flat.find {name: null}, (err, models) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(models.length, 1, 'null name found')
            assert.ok(_.isNull(models[0].get('name')), 'name is null')
            done()

    it 'Handles $ne for strings', (done) ->
      NAME = 'Bob'

      Flat.findOne {$sort: '-created_at'}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!test_model, 'test model found')
        test_model.save {name: NAME}, bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")

          Flat.find {name: {$ne: NAME}}, (err, models) ->
            assert.ok(!err, "No errors: #{err}")

            assert.equal(models.length, BASE_COUNT-1, 'all but NAME found')
            for model in models
              assert.ok(model.get('name') isnt NAME, 'not name attribute')

            Flat.find {name: {$ne: null}}, (err, models) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(models.length, BASE_COUNT, 'all models found')
              for model in models
                assert.ok(!_.isNull(model.get('name')), 'name attributes')

              Flat.find {name: null}, (err, models) ->
                assert.ok(!err, "No errors: #{err}")
                assert.equal(models.length, 0, 'not name null found')
                done()

    it 'Handles $ne with null for strings', (done) ->
      NAME = 'Bob'

      Flat.findOne {$sort: '-created_at'}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!test_model, 'test model found')
        test_model.save {name: null}, bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")

          Flat.find {name: {$ne: NAME}}, (err, models) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(models.length, BASE_COUNT, 'all found')

            Flat.find {name: {$ne: null}}, (err, models) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(models.length, BASE_COUNT-1, 'all models but found null found')
              for model in models
                assert.ok(!_.isNull(model.get('name')), 'name null attribute')

              Flat.find {name: null}, (err, models) ->
                assert.ok(!err, "No errors: #{err}")
                assert.equal(models.length, 1, 'name null found')
                assert.ok(_.isNull(models[0].get('name')), 'name null attribute')
                done()

    it 'Handles $ne for dates', (done) ->
      Flat.find {created_at: {$ne: START_DATE}}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")

        assert.equal(models.length, BASE_COUNT-1, 'all but START DATE found')
        for model in models
          assert.ok(!_.isEqual(model.get('created_at'), START_DATE), 'not created_at attribute')

        Flat.find {created_at: {$ne: null}}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, BASE_COUNT, 'all models found')
          for model in models
            assert.ok(!_.isNull(model.get('created_at')), 'created_at attributes')

          Flat.find {created_at: null}, (err, models) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(models.length, 0, 'not created_at null found')
            done()

    it 'Handles $ne with null for dates', (done) ->
      Flat.findOne {$sort: '-created_at'}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!test_model, 'test model found')
        test_model.save {created_at: null}, bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")

          Flat.find {created_at: {$ne: END_DATE}}, (err, models) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(models.length, BASE_COUNT, 'all found')

            Flat.find {created_at: {$ne: null}}, (err, models) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(models.length, BASE_COUNT-1, 'all models but found null found')
              for model in models
                assert.ok(!_.isNull(model.get('created_at')), 'created_at null attribute')

              Flat.find {created_at: null}, (err, models) ->
                assert.ok(!err, "No errors: #{err}")
                assert.equal(models.length, 1, 'created_at null found')
                assert.ok(_.isNull(models[0].get('created_at')), 'created_at null attribute')
                done()

    it 'Handles $lt and $lte boundary conditions', (done) ->
      Flat.find {created_at: {$lt: START_DATE}}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(models.length, 0, 'no models found')

        Flat.find {created_at: {$lte: START_DATE}}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, 1, 'first model found')
          done()

    it 'Handles $lt and $lte boundary conditions with step', (done) ->
      NEXT_DATE = moment(START_DATE).add('milliseconds', DATE_INTERVAL_MS).toDate()

      Flat.find {created_at: {$lt: NEXT_DATE}}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(models.length, 1, 'one model found')

        Flat.find {created_at: {$lte: NEXT_DATE}}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, 2, 'two models found')
          done()

    it 'Handles $lt and $lte with find equal', (done) ->
      NAME = 'Bob'

      Flat.findOne {$sort: 'created_at'}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!test_model, 'test model found')
        test_model.save {name: NAME}, bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")

          Flat.find {name: NAME, created_at: {$lt: END_DATE}}, (err, models) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(models.length, 1, 'found one model')

            for model in models
              assert.ok(model.get('name') is NAME, 'matching name attribute')

            Flat.find {name: NAME, created_at: {$lte: END_DATE}}, (err, models) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(models.length, 1, 'found one model')

              for model in models
                assert.ok(model.get('name') is NAME, 'matching name attribute')
              done()


    it 'Handles $lt and $lte with find not equal', (done) ->
      NAME = 'Bob'

      Flat.findOne {$sort: 'created_at'}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!test_model, 'test model found')
        test_model.save {name: NAME}, bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")

          Flat.find {name: {$ne: NAME}, created_at: {$lt: END_DATE}}, (err, models) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(models.length, BASE_COUNT-2, 'all models except Bob and last')
            for model in models
              assert.ok(model.get('name') isnt NAME, 'not name attribute')

            Flat.find {name: {$ne: NAME}, created_at: {$lte: END_DATE}}, (err, models) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(models.length, BASE_COUNT-1, 'all models except Bob')
              done()

    it 'Handles $gt and $gte boundary conditions', (done) ->
      Flat.find {created_at: {$gt: END_DATE}}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(models.length, 0, 'no models found')

        Flat.find {created_at: {$gte: END_DATE}}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, 1, 'last model found')
          done()

    it 'Handles $gt and $gte boundary conditions with step', (done) ->
      PREVIOUS_DATE = moment(END_DATE).add('milliseconds', -DATE_INTERVAL_MS).toDate()

      Flat.find {created_at: {$gt: PREVIOUS_DATE}}, (err, models) ->
        assert.ok(!err, "No errors: #{err}")
        assert.equal(models.length, 1, 'one model found')

        Flat.find {created_at: {$gte: PREVIOUS_DATE}}, (err, models) ->
          assert.ok(!err, "No errors: #{err}")
          assert.equal(models.length, 2, 'two models found')
          done()

    it 'Handles $gt and $gte with find equal', (done) ->
      NAME = 'Bob'

      Flat.findOne {$sort: '-created_at'}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!test_model, 'test model found')
        test_model.save {name: NAME}, bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")

          Flat.find {name: NAME, created_at: {$gt: START_DATE}}, (err, models) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(models.length, 1, 'found one model')

            for model in models
              assert.ok(model.get('name') is NAME, 'matching name attribute')

            Flat.find {name: NAME, created_at: {$gte: START_DATE}}, (err, models) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(models.length, 1, 'found one model')

              for model in models
                assert.ok(model.get('name') is NAME, 'matching name attribute')
              done()

    it 'Handles $gt and $gte with find not equal', (done) ->
      NAME = 'Bob'

      Flat.findOne {$sort: '-created_at'}, (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(!!test_model, 'test model found')
        test_model.save {name: NAME}, bbCallback (err) ->
          assert.ok(!err, "No errors: #{err}")

          Flat.find {name: {$ne: NAME}, created_at: {$gt: START_DATE}}, (err, models) ->
            assert.ok(!err, "No errors: #{err}")
            assert.equal(models.length, BASE_COUNT-2, 'all models except Bob and first')
            for model in models
              assert.ok(model.get('name') isnt NAME, 'not name attribute')

            Flat.find {name: {$ne: NAME}, created_at: {$gte: START_DATE}}, (err, models) ->
              assert.ok(!err, "No errors: #{err}")
              assert.equal(models.length, BASE_COUNT-1, 'all models except Bob')
              for model in models
                assert.ok(model.get('name') isnt NAME, 'not name attribute')
              done()

# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> runTests(options, false, callback)
  queue.defer (callback) -> runTests(options, true, callback)
  queue.await callback
