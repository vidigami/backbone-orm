assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed and not options.sync.capabilities(options.database_url or '').embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  describe "JSONUtils.toJSON #{options.$parameter_tags or ''}#{options.$tags}", ->
    Flat = Reverse = Owner = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        model_name: 'Flat'
        urlRoot: "#{DATABASE_URL}/one_flats"
        schema: _.defaults({
          owner: -> ['hasOne', Owner]
        }, BASE_SCHEMA)
        cat: (field, meow, callback) -> callback(null, @get(field) + meow)
        sync: SYNC(Flat)

      class Reverse extends Backbone.Model
        model_name: 'Reverse'
        urlRoot: "#{DATABASE_URL}/one_reverses"
        schema: _.defaults({
          owner: -> ['belongsTo', Owner]
        }, BASE_SCHEMA)
        sync: SYNC(Reverse)

      class Owner extends Backbone.Model
        model_name: 'Owner'
        urlRoot: "#{DATABASE_URL}/one_owners"
        schema: _.defaults({
          flat: -> ['belongsTo', Flat]
          reverses: -> ['hasMany', Reverse]
        }, BASE_SCHEMA)
        cat: (field, meow, callback) -> callback(null, @get(field) + meow)
        sync: SYNC(Owner)

    after (callback) -> Utils.resetSchemas [Flat, Reverse, Owner], callback

    beforeEach (callback) ->
      MODELS = {}

      queue = new Queue(1)
      queue.defer (callback) -> Utils.resetSchemas [Flat, Reverse, Owner], callback
      queue.defer (callback) ->
        create_queue = new Queue()

        create_queue.defer (callback) -> Fabricator.create Flat, BASE_COUNT, {
          name: Fabricator.uniqueId('flat_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owner_')
          created_at: Fabricator.date
        }, (err, models) -> MODELS.owner = models; callback(err)

        create_queue.await callback

      # link and save all
      queue.defer (callback) ->
        save_queue = new Queue()

        for owner in MODELS.owner
          do (owner) -> save_queue.defer (callback) ->
            owner.set({
              flat: MODELS.flat.pop()
              reverses: [MODELS.reverse.pop(), MODELS.reverse.pop()]
            })
            owner.save callback

        save_queue.await callback

      queue.await callback


    # renderTemplate (no dsl)
    it 'renderTemplate (no dsl) handles rendering a single field', (done) ->
      FIELD = 'created_at'
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, FIELD, (err, value) ->
          assert.ok(value, 'Returned a value')
          assert.equal(test_model.get(FIELD), value, "Returned the correct value:\nExpected: #{test_model.get(FIELD)}, Actual: #{value}")
          done()


    it 'renderTemplate (no dsl) rendering a list of fields', (done) ->
      FIELDS = ['created_at', 'name']
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, FIELDS, (err, json) ->
          assert.ok(json, 'Returned json')
          for field in FIELDS
            assert.equal(test_model.get(field), json[field], "Returned the correct value:\nExpected: #{test_model.get(field)}, Actual: #{json[field]}")
          done()


    it 'renderTemplate (no dsl) handles rendering via a function', (done) ->
      FIELDS = ['created_at', 'name']
      fn = (model, options, callback) ->
        json = {}
        (json[field] = model.get(field)) for field in FIELDS
        callback(null, json)
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, fn, (err, json) ->
          assert.ok(json, 'Returned json')
          for field in FIELDS
            assert.equal(test_model.get(field), json[field], "Returned the correct value:\nExpected: #{test_model.get(field)}, Actual: #{json[field]}")
          done()

    # DSL example
    # {
    #   $select:       ['id', 'taken_at', 'rotation', 'width', 'height', 'image_id']
    #   name:          'source_file_name'
    #   album:         {$select: ['id', 'name']}
    #   classroom:     {$select: ['id', 'name']}
    #   is_great:      {method: 'isGreatFor', args: [options.user]}
    #   total_greats:  {key: 'greats', $count: true}
    #   is_fave:       {method: 'isCoverFor', args: [options.user]}
    #   can_delete:    (photo, options, callback) ->
    # }
    #

    # $select: ['created_at', 'name']
    it 'Handles rendering $select with dsl', (done) ->
      FIELDS = ['created_at', 'name']
      TEMPLATE =
        $select: FIELDS
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
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
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          for field in FIELDS
            assert.equal(test_model.get(field), json[field], "Returned the correct value:\nExpected: #{test_model.get(field)}, Actual: #{json[field]}")
          assert.equal(test_model.get(FIELD), json[FIELD_AS], "Returned the correct value:\nExpected: #{test_model.get(FIELD)}, Actual: #{json[FIELD_AS]}")
          done()


    # can_delete: (photo, options, callback) ->
    it 'Handles rendering a function in the dsl', (done) ->
      FIELD = 'name'
      FIELD_AS = 'upper_name'
      TEMPLATE = {}
      TEMPLATE[FIELD_AS] =
        (model, options, callback) -> callback(null, model.get(FIELD).toUpperCase())
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.equal(test_model.get(FIELD).toUpperCase(), json[FIELD_AS], "Returned the correct value:\nExpected: #{test_model.get(FIELD).toUpperCase()}, Actual: #{json[FIELD_AS]}")
          done()

    #   is_great:      {method: 'isGreatFor', args: [options.user]}
    it 'Handles rendering a models method with args in the dsl', (done) ->
      FN = 'cat'
      ARG = 'meow'
      FIELD = 'name'
      FIELD_AS = 'cat_name'
      TEMPLATE = {}
      TEMPLATE[FIELD_AS] = {method: FN, args: [FIELD, ARG] }
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        EXPECTED = test_model.get(FIELD) + ARG
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
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
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
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
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.ok(related = json[FIELD_AS], 'json has related model')
          for field in FIELDS
            assert.ok(related[field], "Related json has a #{field} field")
          done()

    #   album:         {$select: ['id', 'name']}
    it 'Handles retrieving a hasOne relation in the dsl with a cursor query', (done) ->
      FIELD = 'owner'
      FIELDS = ['id', 'name']
      TEMPLATE = {}
      TEMPLATE[FIELD] = {$select: FIELDS}
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.ok(related = json[FIELD], 'json has related model')
          for field in FIELDS
            assert.ok(related[field], "Related json has a #{field} field")
          done()

    #   total_greats:  {key: 'greats', $count: true}
    it 'Handles retrieving a hasOne relation in the dsl with a key and cursor query', (done) ->
      FIELD = 'owner'
      FIELD_AS = 'an_owner'
      FIELDS = ['id', 'name']
      TEMPLATE = {}
      TEMPLATE[FIELD_AS] = {key: FIELD, $select: FIELDS}
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.ok(related = json[FIELD_AS], 'json has related model')
          for field in FIELDS
            assert.ok(related[field], "Related json has a #{field} field")
          done()

    #   album:         {$select: ['id', 'name']}
    it 'Handles retrieving a hasMany relation in the dsl with a cursor query', (done) ->
      FIELD = 'reverses'
      FIELDS = ['id', 'name']
      TEMPLATE = {}
      TEMPLATE[FIELD] = {$select: FIELDS}
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          for owner_json in json
            assert.ok(related = owner_json[FIELD], 'json has related model')
            for field in FIELDS
              assert.ok(related[field], "Related json has a #{field} field")
          done()

    #   total_greats:  {key: 'greats', $count: true}
    it 'Handles retrieving a hasMany relation in the dsl with a key and cursor query', (done) ->
      FIELD = 'reverses'
      FIELD_AS = 'some_reverses'
      FIELDS = ['id', 'name']
      TEMPLATE = {}
      TEMPLATE[FIELD_AS] = {key: FIELD, $select: FIELDS}
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          for owner_json in json
            assert.ok(related = owner_json[FIELD_AS], 'json has related model')
            for field in FIELDS
              assert.ok(related[field], "Related json has a #{field} field")
          done()

