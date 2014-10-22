_ = require 'underscore'
Backbone = require 'backbone'

module.exports = (options) ->
  results = []

  DATABASE_URL = options.database_url or ''
  BASE_SCHEMA = options.schema or {}
  SYNC = options.sync
  BASE_COUNT = 5

  #############################
  # HasMany
  #############################
  (->
    # cache/options
    # conventions/callbacks, conventions/one
    # flat/batch, flat/convenience, flat/page, flat/sort, flat/sync
    # iteration/each, iteration/interval, iteration/stream
    # relational/has_many
    # flat/cursor, flat/find - boolean
    # relational/dsl, relational/has_one, relational/to_json - hasOne Owner
    results.push class Flat extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/flats"
      schema: _.defaults({
        boolean: 'Boolean'
      }, BASE_SCHEMA)
      sync: SYNC(Flat)

    # flat/unique
    results.push class Empty extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/empty"
      schema: _.defaults({
        boolean: 'Boolean'
      }, BASE_SCHEMA)
      sync: SYNC(Empty)

    # compatibility/events, conventions/many, conventions/one
    # relational/dsl, relational/many_to_many, relational/to_json
    # relational/has_many, relational/has_one - another_owner
    results.push class Reverse extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/reverses"
      schema: _.defaults({
        owner: -> ['belongsTo', Owner]
        another_owner: -> ['belongsTo', Owner, as: 'more_reverses']
        foo: 'String'
      }, BASE_SCHEMA)
      sync: SYNC(Reverse)

    # compatibility/events
    # conventions/one - reverse
    # conventions/many
    # relational/has_many - more_reverses, foreign_reverses
    # relational/dsl
    # relational/many_to_many
    # relational/to_json - flat
    results.push class Owner extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/owners"
      schema: _.defaults({
        flats: -> ['hasMany', Flat]
        reverses: -> ['hasMany', Reverse]
        more_reverses: -> ['hasMany', Reverse, as: 'another_owner']
        foreign_reverses: -> ['hasMany', ForeignReverse]
      }, BASE_SCHEMA)
      sync: SYNC(Owner)

    # relational/has_many, relational/has_one
    results.push class ForeignReverse extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/foreign_reverses"
      schema: _.defaults({
        owner: -> ['belongsTo', Owner, foreign_key: 'ownerish_id']
      }, BASE_SCHEMA)
      sync: SYNC(ForeignReverse)
  )()

  #############################
  # HasOne/BelongsTo
  #############################
  (->
    results.push class Flat extends Backbone.Model
      model_name: 'Flat'
      urlRoot: "#{DATABASE_URL}/one_flats"
      schema: _.defaults({
        owner: -> ['hasOne', Owner]
      }, BASE_SCHEMA)
      sync: SYNC(Flat)

    results.push class Reverse extends Backbone.Model
      model_name: 'Reverse'
      urlRoot: "#{DATABASE_URL}/one_reverses"
      schema: _.defaults({
        owner: -> ['belongsTo', Owner]
        owner_as: -> ['belongsTo', Owner, as: 'reverse_as']
      }, BASE_SCHEMA)
      sync: SYNC(Reverse)

    results.push class ForeignReverse extends Backbone.Model
      model_name: 'ForeignReverse'
      urlRoot: "#{DATABASE_URL}/one_foreign_reverses"
      schema: _.defaults({
        owner: -> ['belongsTo', Owner, foreign_key: 'ownerish_id']
      }, BASE_SCHEMA)
      sync: SYNC(ForeignReverse)

    results.push class Owner extends Backbone.Model
      model_name: 'Owner'
      urlRoot: "#{DATABASE_URL}/one_owners"
      schema: _.defaults({
        flat: -> ['belongsTo', Flat, embed: options.embed]
        reverse: -> ['hasOne', Reverse]
        reverse_as: -> ['hasOne', Reverse, as: 'owner_as']
        foreign_reverse: -> ['hasOne', ForeignReverse]
      }, BASE_SCHEMA)
      sync: SYNC(Owner)
  )()

  #############################
  # Many To Many
  #############################
  (->
    results.push class Reverse extends Backbone.Model
      model_name: 'Reverse'
      urlRoot: "#{DATABASE_URL}/many_to_many_reverses"
      schema: _.defaults({
        owners: -> ['hasMany', Owner]
      }, BASE_SCHEMA)
      sync: SYNC(Reverse)

    results.push class Owner extends Backbone.Model
      model_name: 'Owner'
      urlRoot: "#{DATABASE_URL}/many_to_many_owners"
      schema: _.defaults({
        reverses: -> ['hasMany', Reverse]
      }, BASE_SCHEMA)
      sync: SYNC(Owner)
  )()

  #############################
  # Other
  #############################
  (->
    # collection/sync
    results.push class Model extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/models"
      schema: BASE_SCHEMA
      sync: SYNC(Model)

    # relational/has_many, relational/self
    results.push class SelfReference extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/self_references"
      schema: _.defaults({
        owner: -> ['belongsTo', SelfReference, foreign_key: 'owner_id', as: 'self_references']
        self_references: -> ['hasMany', SelfReference, as: 'owner']
      }, BASE_SCHEMA)
      sync: SYNC(SelfReference)

    # relational/has_one
    class Owner extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/owners"
      schema: _.defaults({
        flat: -> ['belongsTo', Flat, embed: options.embed]
        reverse: -> ['hasOne', Reverse]
        reverse_as: -> ['hasOne', Reverse, as: 'owner_as']
        foreign_reverse: -> ['hasOne', ForeignReverse]
      }, BASE_SCHEMA)
      sync: SYNC(Owner)

    # relational/join_table
    results.push class FirstModel extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/firsts"
      schema: _.defaults({
        seconds: -> ['hasMany', SecondModel]
      }, BASE_SCHEMA)
      sync: SYNC(FirstModel)

    # relational/join_table
    results.push class SecondModel extends Backbone.Model
      urlRoot: "#{DATABASE_URL}/seconds"
      schema: _.defaults({
        firsts: -> ['hasMany', FirstModel]
      }, BASE_SCHEMA)
      sync: SYNC(SecondModel)
  )()

  return results
