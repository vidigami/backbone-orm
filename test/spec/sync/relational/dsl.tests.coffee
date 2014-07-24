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

  describe "JSON DSL #{options.$parameter_tags or ''}#{options.$tags}", ->
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
          flat: -> ['belongsTo', Flat, embed: options.embed]
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
          updated_at: Fabricator.date
        }, (err, models) -> MODELS.flat = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Reverse, 2*BASE_COUNT, {
          name: Fabricator.uniqueId('reverse_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
        }, (err, models) -> MODELS.reverse = models; callback(err)
        create_queue.defer (callback) -> Fabricator.create Owner, BASE_COUNT, {
          name: Fabricator.uniqueId('owner_')
          created_at: Fabricator.date
          updated_at: Fabricator.date
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

    it 'renderTemplate (no dsl) handles a list of fields', (done) ->
      FIELDS = ['created_at', 'name']
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, FIELDS, (err, json) ->
          assert.ok(json, 'Returned json')
          for field in FIELDS
            assert.equal(test_model.get(field), json[field], "Returned the correct value:\nExpected: #{test_model.get(field)}, Actual: #{json[field]}")
          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    it 'renderTemplate (no dsl) handles rendering via a function', (done) ->
      FIELDS = ['created_at', 'name']
      template = (model, options, callback) ->
        json = {}
        (json[field] = model.get(field)) for field in FIELDS
        callback(null, json)
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, template, (err, json) ->
          assert.ok(json, 'Returned json')
          for field in FIELDS
            assert.equal(test_model.get(field), json[field], "Returned the correct value:\nExpected: #{test_model.get(field)}, Actual: #{json[field]}")
          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    # DSL example
    # {
    #   $select:       'id'
    #   $select:       ['id', 'taken_at', 'rotation', 'width', 'height', 'image_id']
    #   name:          'source_file_name'
    #   album:         {$select: ['id', 'name']}
    #   classroom:     {$select: ['id', 'name']}
    #   is_great:      {method: 'isGreatFor', args: [options.user]}
    #   total_greats:  {key: 'greats', query: {$count: true}}
    #   is_fave:       {method: 'isCoverFor', args: [options.user]}
    #   can_delete:    (photo, options, callback) ->
    # }
    #

    # $select: 'id'
    it 'Handles rendering $select for single string with dsl', (done) ->
      FIELD = 'id'
      TEMPLATE =
        $select: FIELD
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.equal(test_model.get(FIELD), json[FIELD], "Returned the correct value:\nExpected: #{test_model.get(FIELD)}, Actual: #{json[FIELD]}")
          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

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
          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    # updated: 'updated_at'
    it 'Handles rendering $select and a name: "string" with dsl', (done) ->
      FIELDS = ['created_at']
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
          assert.ok(!json.name, 'Does not have an excluded field')
          done()

    # $select: ['name', 'reverses']
    it 'Handles rendering a related field with $select', (done) ->
      FIELD = 'name'
      RELATED_FIELD = 'flat'
      MANY_FIELD = 'reverses'
      TEMPLATE =
        $select: [FIELD, RELATED_FIELD, MANY_FIELD]
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.equal(test_model.get(FIELD), json[FIELD], "Returned the correct value:\nExpected: #{test_model.get(FIELD)}, Actual: #{json[FIELD]}")

          assertRelated = (model_json) ->
            assert.ok(model_json, 'Returned related model')
            assert.ok(!(model_json instanceof Backbone.Model), 'Related model is not a backbone model')
            assert.ok(model_json.name, 'Related model has data')

          assertRelated(json[RELATED_FIELD])
          assertRelated(model_json) for model_json in json[MANY_FIELD]

          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    # owner: {$select: ['name', 'flat']}
    it 'Handles rendering a related fields with $select', (done) ->
      FIELD = 'name'
      RELATED_FIELD = 'owner'
      SECOND_RELATED_FIELD = 'reverses'
      TEMPLATE = {}
      TEMPLATE[RELATED_FIELD] = {$select: [FIELD, SECOND_RELATED_FIELD]}
      Reverse.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')

        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ifError(err)
          assert.ok(json, 'Returned json')

          assertRelated = (model_json) ->
            assert.ok(model_json, 'Returned related model')
            assert.ok(!(model_json instanceof Backbone.Model), 'Related model is not a backbone model')
            if _.isArray(model_json)
              assert.ok(item_json.name, 'Related model has data') for item_json in model_json
            else
              assert.ok(model_json.name, 'Related model has data')

          assertRelated(json[RELATED_FIELD])
          assertRelated(json[RELATED_FIELD][SECOND_RELATED_FIELD])

          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    # flat: {$select: ['name', 'reverses']}
    # TODO: fails on mongo with embed: true
    it 'Handles rendering a related fields hasMany related field with $select', (done) ->
      FIELD = 'name'
      RELATED_FIELD = 'owner'
      SECOND_RELATED_FIELD = 'reverses'
      TEMPLATE = {}
      TEMPLATE[RELATED_FIELD] = {$select: [FIELD, SECOND_RELATED_FIELD]}
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')

          unless options.embed # embed doesn't know reverse
            assertRelated = (model_json) ->
              assert.ok(model_json, 'Returned related model')
              assert.ok(!(model_json instanceof Backbone.Model), 'Related model is not a backbone model')
              assert.ok(model_json.name, 'Related model has data')

            assertRelated(json[RELATED_FIELD])
            assertRelated(model_json) for model_json in json[RELATED_FIELD][SECOND_RELATED_FIELD]

          assert.ok(!json.updated_at, 'Does not have an excluded field')
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
          assert.ok(!json.updated_at, 'Does not have an excluded field')
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
          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    #   a_reverse:    'reverse'
    it 'Handles rendering a relation specified by a string', (done) ->
      FIELD = 'flat'
      FIELD_AS = 'a_flat'
      TEMPLATE = {}
      TEMPLATE[FIELD_AS] = FIELD
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.ok(json[FIELD_AS].name, 'Has data')
          assert.ok(!(json instanceof Backbone.Model), 'Is not a backbone model')
          done()

    #   album:         {$select: ['id', 'name']}
    # TODO: fails on mongo with embed: true
    it 'Handles rendering a belongsTo relation in the dsl with a cursor query', (done) ->
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
          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    #   an_owner:         {key: 'owner', $select: ['id', 'name']}
    # TODO: fails on mongo with embed: true
    it 'Handles rendering a belongsTo relation in the dsl with a key and cursor query', (done) ->
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
          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    #   album:         {$select: ['id', 'name']}
    it 'Handles rendering a hasOne relation in the dsl with a cursor query', (done) ->
      FIELD = 'owner'
      FIELDS = ['id', 'name']
      TEMPLATE = {}
      TEMPLATE[FIELD] = {$select: FIELDS}
      Flat.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')

          unless options.embed # embed doesn't know reverse
            assert.ok(related = json[FIELD], 'json has related model')
            for field in FIELDS
              assert.ok(related[field], "Related json has a #{field} field")

          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    # an_owner:         {key: 'owner', $select: ['id', 'name']}
    it 'Handles rendering a hasOne relation in the dsl with a key and cursor query', (done) ->
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

          unless options.embed # embed doesn't know reverse
            assert.ok(related = json[FIELD_AS], 'json has related model')
            for field in FIELDS
              assert.ok(related[field], "Related json has a #{field} field")

          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    #   album:         {$select: ['id', 'name']}
    it 'Handles rendering a hasMany relation in the dsl with a cursor query', (done) ->
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
            assert.ok(!owner_json.updated_at, 'Does not have an excluded field')
          done()

    #   some_reverses:         {key: 'reverses', $select: ['id', 'name']}
    it 'Handles rendering a hasMany relation in the dsl with a key and cursor query', (done) ->
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
            assert.ok(!owner_json.updated_at, 'Does not have an excluded field')
          done()

    # reverse_count:         {key: 'reverses', query: {$count: true}}
    it 'Handles rendering a hasMany relation in the dsl with a $count query', (done) ->
      REVERSE_COUNT = 2
      FIELD = 'reverse_count'
      TEMPLATE = {}
      TEMPLATE[FIELD] = {key: 'reverses', query: {$count: true}}
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.ok(count = json[FIELD], 'json has the related count')
          assert.equal(REVERSE_COUNT, count, "Returned the correct value:\nExpected: #{REVERSE_COUNT}, Actual: #{count}")
          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    # reverses:         {key: 'reverses', query: {$count: true}}
    it 'Handles rendering a hasMany relation in the dsl with a template with function', (done) ->
      REVERSE_COUNT = 2
      FIELD = 'reverse_count'
      TEMPLATE = {}
      TEMPLATE[FIELD] = {key: 'reverses', query: {$count: true}}
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.ok(count = json[FIELD], 'json has the related count')
          assert.equal(REVERSE_COUNT, count, "Returned the correct value:\nExpected: #{REVERSE_COUNT}, Actual: #{count}")
          assert.ok(!json.updated_at, 'Does not have an excluded field')
          done()

    # TODO
    # a_flat: {key: 'flat', template: (model, options, callback) -> }
    it 'Handles rendering a related models template function in the dsl', (done) ->
      FIELD = 'flat'
      FIELD_AS = 'a_flat'
      TEMPLATE = {}
      TEMPLATE[FIELD_AS] =
        key: FIELD
        template: (model, options, callback) -> callback(null, { name: model.get('name')})
      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')
          assert.ok(json[FIELD_AS], 'Has related model')
          assert.ok(json[FIELD_AS].name, 'Related model has json set by function')
          assert.ok(!json[FIELD_AS].updated_at, 'Related model does not have an excluded field')
          done()

    #   All
    it 'Handles rendering a complete dsl', (done) ->
      REVERSE_COUNT = 2

      TEMPLATE =
        $select:          ['id', 'name']
        this_name:        'name'
        reverses:         {$select: ['id', 'name']}
        reverse_count:    {key: 'reverses', query: {$count: true}}
        reverse_count2:   {key: 'reverses', template: {$count: true}}
        reverses_upnames: {key: 'reverses', template: (model, options, callback) -> callback(null, model.get('name').toUpperCase())}
        mew:              {method: 'cat', args: ['name', 'meow']}
        upper_name:       (model, options, callback) -> callback(null, model.get('name').toUpperCase())

      Owner.findOne (err, test_model) ->
        assert.ok(!err, "No errors: #{err}")
        assert.ok(test_model, 'found model')
        JSONUtils.renderTemplate test_model, TEMPLATE, (err, json) ->
          assert.ok(json, 'Returned json')

          assert.equal(test_model.id, json.id, "Returned the correct value:\nExpected: #{test_model.id}, Actual: #{json.id}")
          assert.equal(test_model.get('name'), json.name, "Returned the correct value:\nExpected: #{test_model.get('name')}, Actual: #{json.name}")
          assert.equal(test_model.get('name'), json.this_name, "Returned the correct value:\nExpected: #{test_model.get('name')}, Actual: #{json.this_name}")

          for reverse in json.reverses
            assert.ok(reverse.id, 'Has reverses with the correct fields')
            assert.ok(reverse.name, 'Has reverses with the correct fields')

          assert.equal(REVERSE_COUNT, json.reverse_count, "Returned the correct value:\nExpected: #{REVERSE_COUNT}, Actual: #{json.reverse_count}")
          assert.equal(REVERSE_COUNT, json.reverse_count2, "Returned the correct value:\nExpected: #{REVERSE_COUNT}, Actual: #{json.reverse_count2}")

          for reverse_upname in json.reverses_upnames
            assert.ok(_.isString(reverse_upname), 'Has reverses with the correct fields')

          mew = test_model.get('name') + 'meow'
          assert.equal(mew, json.mew, "Returned the correct value:\nExpected: #{mew}, Actual: #{json.mew}")

          upper_name = test_model.get('name').toUpperCase()
          assert.equal(upper_name, json.upper_name, "Returned the correct value:\nExpected: #{upper_name}, Actual: #{json.upper_name}")

          done()

