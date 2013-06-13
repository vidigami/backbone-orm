util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'

BelongsTo = require './relations/belongs_to'
HasOne = require './relations/has_one'
HasMany = require './relations/has_many'

# HACK: global monkey patch - WHY IS THIS NEEDED?
_original_get = Backbone.Model::get
Backbone.Model::get = (key, callback) ->
  value = _original_get.call(@, key)
  callback(null, value) if callback
  return value

module.exports = class Schema
  @types:
    String: 'String'
    Date: 'Date'
    Boolean: 'Boolean'
    Integer: 'Integer'
    Float: 'Float'

  constructor: (@model_type) ->
    @_parse()
    @_monkeyPatchModel()

  initialize: ->
    for key, options of @relations
      options = options() if _.isFunction(options)
      throw new Error "parseRelations, relation does not resolve to an array of [type, model, options]. Options: #{util.inspect(options)}" unless _.isArray(options)

      type_name = options[0]
      if type_name is 'hasOne'
        relation = @relations[key] = new HasOne(@model_type, key, options.slice(1))
      else if type_name is 'belongsTo'
        relation = @relations[key] = new BelongsTo(@model_type, key, options.slice(1))
      else if type_name is 'hasMany'
        relation = @relations[key] = new HasMany(@model_type, key, options.slice(1))
      else
        throw new Error "Unrecognized relationship: #{util.inspect(options)}"
      @relations_ids[relation.ids_accessor] = relation if relation.ids_accessor

  _parse: ->
    schema = _.result(@model_type, 'schema') or {}
    @fields ={}; @relations ={}

    for key, options of schema
      type_name = if _.isArray(options) then options[0] else options
      if type = Schema.types[type_name] then (@fields[key] = type) else (@relations[key] = options) # save relations for later binding

  _monkeyPatchModel: ->
    _schema = @

    _set = @model_type::set
    @model_type::set = (attributes={}, value, options) ->
      (attributes[attributes] = value; options = value) if _.isString(attributes)

      for key, value of attributes
        if relation = _schema.relations[key] or relation = _schema.relations_ids[key]
          relation.set(@, key, value, options, _set)
        else
          _set.call(@, key, value, options)
      return @

    _get = @model_type::get
    @model_type::get = (key, callback) ->
      if relation = _schema.relations[key] or relation = _schema.relations_ids[key]
        return relation.get(@, key, callback)
      else
        value = _get.call(@, key)
        callback(null, value) if callback
        return value

    _toJSON = @model_type::toJSON
    @model_type::toJSON = ->
      return @get('id') if @_locked > 0
      @_locked or= 0
      @_locked++

      toJSON = (item) -> if (item and item.get and item.toJSON) then item.toJSON() else item

      json = _.clone(@attributes)
      for key, value of json
        continue unless value
        if value.models
          json[key] = _.map(value.models, toJSON)
        else if _.isArray(value)
          json[key] = _.map(value, toJSON)
        else if (value.get and value.toJSON) # model signature
          json[key] = toJSON(value)

      @_locked--
      return json