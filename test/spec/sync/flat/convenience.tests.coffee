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

  describe "Convenience Methods #{options.$parameter_tags or ''}#{options.$tags} @convenience", ->
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

    describe 'count', ->
      it 'Handles a count query', (done) ->
        Flat.count (err, count) ->
          assert.ifError(err)
          assert.equal(count, BASE_COUNT, "Expected: #{count}. Actual: #{BASE_COUNT}")
          done()

      it 'counts by query', (done) ->
        bob = new Flat({name: 'Bob'})

        queue = new Queue(1)
        queue.defer (callback) -> bob.save callback

        queue.defer (callback) ->
          Flat.count {name: 'Bob'}, (err, count) ->
            assert.equal(count, 1, 'found Bob through query')
            callback(err)

        queue.defer (callback) ->
          Flat.count {name: 'Fred'}, (err, count) ->
            assert.equal(count, 0, 'no Fred')
            callback(err)

        queue.defer (callback) ->
          Flat.count {}, (err, count) ->
            assert.ok(count >= 1, 'found Bob through empty query')
            callback(err)

        queue.await done

      it 'destroy all', (done) ->
        Flat.count (err, count) ->
          assert.ifError(err)
          assert.equal(count, BASE_COUNT)

          Flat.destroy (err) ->
            assert.ifError(err)

            Flat.count (err, count) ->
              assert.ifError(err)
              assert.equal(count, 0)
              done()

      it 'counts by query with multiple', (done) ->
        bob = new Flat({name: 'Bob'})
        fred = new Flat({name: 'Fred'})

        queue = new Queue(1)
        queue.defer (callback) -> bob.save callback
        queue.defer (callback) -> fred.save callback

        queue.defer (callback) ->
          Flat.count {name: 'Bob'}, (err, count) ->
            assert.equal(count, 1, 'found Bob through query')
            callback(err)

        queue.defer (callback) ->
          Flat.count {name: 'Fred'}, (err, count) ->
            assert.equal(count, 1, 'Fred')
            callback(err)

        queue.defer (callback) ->
          Flat.count {}, (err, count) ->
            assert.ok(count >= 2, 'found Bob and Fred through empty query')
            callback(err)

        queue.defer (callback) ->
          Flat.count (err, count) ->
            assert.ok(count >= 2, 'found Bob and Fred when skipping query')
            callback(err)

        queue.await done

    describe 'all', ->
      it 'Handles an all query', (done) ->
        Flat.all (err, models) ->
          assert.ifError(err)
          assert.equal(models.length, BASE_COUNT, 'counted expected number of albums')
          done()

    describe 'destroy', ->
      it 'Has a short hand for id', (done) ->
        Flat.findOne (err, model) ->
          assert.ifError(err)
          assert.ok(model, 'found a model')

          Flat.destroy id = model.id, (err) ->
            assert.ifError(err)

            Flat.findOne id, (err, model) ->
              assert.ifError(err)
              assert.ok(!model, 'model was destroyed')
              done()

    describe 'exists', ->
      it 'Handles an exist with no query', (done) ->
        Flat.exists (err, exists) ->
          assert.ifError(err)
          assert.ok(exists, 'something exists')
          done()

      it 'Handles an exist query', (done) ->
        Flat.findOne (err, model) ->
          assert.ifError(err)
          assert.ok(model, 'found a model')

          Flat.exists {name: model.get('name')}, (err, exists) ->
            assert.ifError(err)
            assert.ok(exists, "the model exists by name. Expected: #{true}. Actual: #{exists}")

            Flat.exists {name: "#{model.get('name')}_thingy"}, (err, exists) ->
              assert.ifError(err)
              assert.ok(!exists, "the model does not exist by bad name. Expected: #{false}. Actual: #{exists}")

              Flat.exists {created_at: model.get('created_at')}, (err, exists) ->
                assert.ifError(err)
                assert.ok(exists, "the model exists by created_at. Expected: #{true}. Actual: #{exists}")

                Flat.exists {created_at: new Date('2001-04-25T01:32:21.196Z')}, (err, exists) ->
                  assert.ifError(err)
                  assert.ok(!exists, "the model does not exist by bad created_at. Expected: #{false}. Actual: #{exists}")
                  done()
