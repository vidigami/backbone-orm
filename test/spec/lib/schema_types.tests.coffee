assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

_.each BackboneORM.TestUtils.optionSets(), exports = (options) ->
  options = _.extend({}, options, __test__parameters) if __test__parameters?
  return if options.embed

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  describe "Model.schema#idType #{options.$parameter_tags or ''}#{options.$tags} @schema", ->
    Flat = Reverse = Owner = null
    owner_id_type = owner_id_parsed_result = reverse_id_type = reverse_id_parsed_result = null
    before ->
      BackboneORM.configure {model_cache: {enabled: !!options.cache, max: 100}}

      class Flat extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/flats"
        schema: _.extend BASE_SCHEMA,
          a_string: 'String'
        sync: SYNC(Flat)

      class Reverse extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/reverses"
        schema: _.defaults({
          owner: -> ['belongsTo', Owner]
          another_owner: -> ['belongsTo', Owner, as: 'more_reverses']
          many_owners: -> ['hasMany', Owner, as: 'many_reverses']
        }, BASE_SCHEMA)
        sync: SYNC(Reverse)

      class Owner extends Backbone.Model
        urlRoot: "#{DATABASE_URL}/owners"
        schema: _.defaults({
          a_string: 'String'
          flats: -> ['hasMany', Flat]
          reverses: -> ['hasMany', Reverse]
          more_reverses: -> ['hasMany', Reverse, as: 'another_owner']
          many_reverses: -> ['hasMany', Reverse, as: 'many_owners']
        }, BASE_SCHEMA)
        sync: SYNC(Owner)

      owner_id_type = Flat.schema().idType()
      owner_id_parsed_result = if owner_id_type is 'Integer' then 1 else '1'
      reverse_id_type = Reverse.schema().idType()
      reverse_id_parsed_result = if reverse_id_type is 'Integer' then 1 else '1'

    after (callback) -> Utils.resetSchemas [Flat], callback
    beforeEach (callback) ->
      queue = new Queue(1)
      queue.defer (callback) -> Utils.resetSchemas [Flat], callback
      queue.await callback

    describe 'schema', ->
      it 'should return Integer for the schema type of the id', ->
        assert.equal(Flat.schema().type('id'), owner_id_type)
      it 'should return Integer for the schema type of a belongsTo id', ->
        assert.equal(Reverse.schema().type('owner_id'), owner_id_type)
      it 'should return Integer for the schema type of a hasMany id', ->
        assert.equal(Owner.schema().type('reverse_ids'), reverse_id_type)
      it 'should parse a related belongsTo id as an Integer (dot)', ->
        assert.equal(Reverse.schema().idType('owner.reverses.id'), reverse_id_type)
      it 'should parse a related belongsTo id as an Integer (underscore)', ->
        assert.equal(Reverse.schema().idType('owner.reverse_id'), reverse_id_type)
      it 'should parse a related hasMany id as an Integer', ->
        assert.equal(Owner.schema().idType('reverses.another_owner_id'), owner_id_type)

    describe 'JSONUtils', ->
      it 'should parse a belongsTo id as the correct type', ->
        assert.strictEqual(JSONUtils.parse({'owner_id': '1'}, Reverse)['owner_id'], owner_id_parsed_result)
      it 'should parse a hasMany id as the correct type', ->
        assert.strictEqual(JSONUtils.parse({'reverse_id': '1'}, Owner)['reverse_id'], reverse_id_parsed_result)
      it 'should parse a related belongsTo id as the correct type', ->
        assert.strictEqual(JSONUtils.parse({'owner.reverse_id': '1'}, Reverse)['owner.reverse_id'], reverse_id_parsed_result)
      it 'should parse a related hasMany id as the correct type', ->
        assert.strictEqual(JSONUtils.parse({'reverses.another_owner_id': '1'}, Owner)['reverses.another_owner_id'], owner_id_parsed_result)
