util = require 'util'
assert = require 'assert'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

Fabricator = require '../../../fabricator'
Utils = require '../../../lib/utils'
JSONUtils = require '../../../lib/json_utils'

runTests = (options, cache) ->
  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 1
  MODELS_JSON = null

  class Flat extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/flats"
    @schema: BASE_SCHEMA
    cat: (field, meow, callback) -> callback(null, @get(field) + meow)
    sync: SYNC(Flat, cache)

  class Reverse extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/reverses"
    @schema: _.defaults({
      owner: -> ['belongsTo', Owner]
    }, BASE_SCHEMA)
    sync: SYNC(Reverse, cache)

  class Owner extends Backbone.Model
    urlRoot: "#{DATABASE_URL}/owners"
    @schema: _.defaults({
      flats: -> ['hasMany', Flat]
      reverses: -> ['hasMany', Reverse]
    }, BASE_SCHEMA)
    sync: SYNC(Owner, cache)

  describe "JSONUtils.renderJSON (cache: #{cache})", ->

    beforeEach (done) ->
      MODELS = {}

      queue = new Queue(1)

      # destroy all
      queue.defer (callback) ->
        destroy_queue = new Queue()

        destroy_queue.defer (callback) -> Flat.destroy callback
        destroy_queue.defer (callback) -> Reverse.destroy callback
        destroy_queue.defer (callback) -> Owner.destroy callback

        destroy_queue.await callback

      # create all
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create(Flat, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err))
        create_queue.defer (callback) -> Fabricator.create(Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owner_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err))

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        for owner in MODELS.owner
          do (owner) ->
            owner.set({
              flats: [MODELS.flat.pop(), MODELS.flat.pop()]
              reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]
            })
            save_queue.defer (callback) -> owner.save {}, Utils.bbCallback callback

        save_queue.await callback

      queue.await done


    it 'Handles rendering a single field', (done) ->
      FIELD = 'created_at'
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderJSON test_model, FIELD, (err, value) ->
          assert.ok(value, 'Returned a value')
          assert.equal(test_model.get(FIELD), value, "Returned the correct value:\nExpected: #{test_model.get(FIELD)}, Actual: #{value}")
          done()


    it 'Handles rendering a list of fields', (done) ->
      FIELDS = ['created_at', 'name']
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderJSON test_model, FIELDS, (err, json) ->
          assert.ok(json, 'Returned json')
          for field in FIELDS
            assert.equal(test_model.get(field), json[field], "Returned the correct value:\nExpected: #{test_model.get(field)}, Actual: #{json[field]}")
          done()


    it 'Handles rendering via a function', (done) ->
      FIELDS = ['created_at', 'name']
      fn = (model, options, callback) ->
        json = {}
        (json[field] = model.get(field)) for field in FIELDS
        callback(null, json)
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderJSON test_model, fn, (err, json) ->
          assert.ok(json, 'Returned json')
          for field in FIELDS
            assert.equal(test_model.get(field), json[field], "Returned the correct value:\nExpected: #{test_model.get(field)}, Actual: #{json[field]}")
          done()

    # $select: ['created_at', 'name']
    it 'Handles rendering $select with dsl', (done) ->
      FIELDS = ['created_at', 'name']
      TEMPLATE =
        $select: FIELDS
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderJSON test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          for field in FIELDS
            assert.equal(test_model.get(field), json[field], "Returned the correct value:\nExpected: #{test_model.get(field)}, Actual: #{json[field]}")
          done()

    # updated: 'updated_at'
    it 'Handles rendering $select and a name: "string" with dsl', (done) ->
      FIELDS = ['created_at', 'name']
      FIELD = 'updated_at'
      FIELD_AS = 'updated'
      TEMPLATE =
        $select: FIELDS
      TEMPLATE[FIELD_AS] = FIELD
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderJSON test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          for field in FIELDS
            assert.equal(test_model.get(field), json[field], "Returned the correct value:\nExpected: #{test_model.get(field)}, Actual: #{json[field]}")
          assert.equal(test_model.get(FIELD), json[FIELD_AS], "Returned the correct value:\nExpected: #{test_model.get(FIELD)}, Actual: #{json[FIELD_AS]}")
          done()


    # can_delete: {fn: (photo, options, callback) -> }
    it 'Handles rendering a function in the dsl', (done) ->
      FIELD = 'name'
      FIELD_AS = 'upper_name'
      TEMPLATE = {}
      TEMPLATE[FIELD_AS] =
        fn: (model, options, callback) -> callback(null, model.get(FIELD).toUpperCase())
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderJSON test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.equal(test_model.get(FIELD).toUpperCase(), json[FIELD_AS], "Returned the correct value:\nExpected: #{test_model.get(FIELD).toUpperCase()}, Actual: #{json[FIELD_AS]}")
          done()


    #   is_great:      {fn: 'isGreatFor', args: [options.user]}
    it 'Handles rendering a models method in the dsl', (done) ->
      FN = 'cat'
      ARG = 'meow'
      FIELD = 'name'
      FIELD_AS = 'cat_name'
      TEMPLATE = {}
      TEMPLATE[FIELD_AS] = {fn: FN, args: [FIELD, ARG] }
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        EXPECTED = test_model.get(FIELD) + ARG
        JSONUtils.renderJSON test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.equal(EXPECTED, json[FIELD_AS], "Returned the correct value:\nExpected: #{EXPECTED}, Actual: #{json[FIELD_AS]}")
          done()

#   album:         {$select: ['id', 'name']}
    it 'Handles retrieving a belongsTo relation in the dsl with a cursor query', (done) ->
      FIELD = 'owner'
      FIELDS = ['id', 'name']
      TEMPLATE = {}
      TEMPLATE[FIELD] = {$select: FIELDS}
      Reverse.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderJSON test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.ok(related = json[FIELD], 'json has related model')
          for field in FIELDS
            assert.ok(related[field], "Related json has a #{field} field")
          done()

    #   total_greats:  {key: 'greats', $count: true}
    it 'Handles retrieving a belongsTo relation in the dsl with a key and cursor query', (done) ->
      FIELD = 'owner'
      FIELD_AS = 'an_owner'
      FIELDS = ['id', 'name']
      TEMPLATE = {}
      TEMPLATE[FIELD_AS] = {key: FIELD, $select: FIELDS}
      Reverse.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderJSON test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.ok(related = json[FIELD_AS], 'json has related model')
          for field in FIELDS
            assert.ok(related[field], "Related json has a #{field} field")
          done()

# {
#   $select:       ['id', 'taken_at', 'rotation', 'width', 'height', 'image_id']
#   name:          'source_file_name'
#   album:         {$select: ['id', 'name']}
#   classroom:     {$select: ['id', 'name']}
#   is_great:      {fn: 'isGreatFor', args: [options.user]}
#   total_greats:  {key: 'greats', $count: true}
#   is_fave:       {fn: 'isCoverFor', args: [options.user]}
#   can_delete:    {fn: (photo, options, callback) ->  }
# }
#

    #   album:         {$select: ['id', 'name']}
#    it 'Handles retrieving a hasMany relation in the dsl with a cursor query', (done) ->
#      FIELD = 'reverse'
#      FIELDS = ['id', 'name']
#      TEMPLATE = {}
#      TEMPLATE[FIELD] = {$select: FIELDS}
#      Reverse.findOne (err, test_model) ->
#        assert.ok(!err, "No errors: #{err}")
#        assert.ok(test_model, 'found model')
#        JSONUtils.renderJSON test_model, TEMPLATE, (err, json) ->
#          assert.ok(json, 'Returned json')
#          assert.ok(related = json[FIELD], 'json has related model')
#          for field in FIELDS
#            assert.ok(related[field], "Related json has a #{field} field")
#          done()
#
#    #   total_greats:  {key: 'greats', $count: true}
#    it 'Handles retrieving a hasMany relation in the dsl with a key and cursor query', (done) ->
#      FIELD = 'reverse'
#      FIELD_AS = 'a_reverse'
#      FIELDS = ['id', 'name']
#      TEMPLATE = {}
#      TEMPLATE[FIELD_AS] = {key: FIELD, $select: FIELDS}
#      Reverse.findOne (err, test_model) ->
#        assert.ok(!err, "No errors: #{err}")
#        assert.ok(test_model, 'found model')
#        JSONUtils.renderJSON test_model, TEMPLATE, (err, json) ->
#          assert.ok(json, 'Returned json')
#          assert.ok(related = json[FIELD_AS], 'json has related model')
#          for field in FIELDS
#            assert.ok(related[field], "Related json has a #{field} field")
#          done()


# TODO: explain required set up

# each model should have available attribute 'id', 'name', 'created_at', 'updated_at', etc....
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  runTests(options, false)
#  runTests(options, true)
