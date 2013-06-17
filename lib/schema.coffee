util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'

One = require './relations/one'
Many = require './relations/many'

# # HACK: global monkey patch - WHY IS THIS NEEDED?
# _original_get = Backbone.Model::get
# Backbone.Model::get = (key, callback) ->
#   value = _original_get.call(@, key)
#   callback(null, value) if callback
#   return value

module.exports = class Schema
  @types:
    String: 'String'
    Date: 'Date'
    Boolean: 'Boolean'
    Integer: 'Integer'
    Float: 'Float'

  constructor: (@model_type) ->
    @fields ={}; @relations ={}; @ids_accessor = {}
    @_parse()
    @_monkeyPatchModel()

  initialize: ->
    for key, options of @relations
      options = @_parseFieldOptions(options()) if _.isFunction(options)
      switch options.type
        when 'hasOne', 'belongsTo' then relation = @relations[key] = new One(@model_type, key, options)
        when 'hasMany' then relation = @relations[key] = new Many(@model_type, key, options)
        else throw new Error "Unrecognized relationship: #{util.inspect(options)}"
      @ids_accessor[relation.ids_accessor] = relation if relation.ids_accessor
    return

  _parseFieldOptions: (options) ->
    # convert to an object
    return {type: options} if _.isString(options)
    return options unless _.isArray(options)

    # type
    result = {}
    if _.isString(options[0])
      result.type = options[0]
      options = options.slice(1)
      return result if options.length is 0

    # reverse relation
    if _.isFunction(options[0])
      result.reverse_model_type = options[0]
      options = options.slice(1)

    # too many options
    throw new Error "Unexpected field options array: #{util.inspect(options)}" if options.length > 1

    # options object
    _.extend(result, options[0]) if options.length is 1
    return result

  _parse: ->
    schema = _.result(@model_type, 'schema') or {}

    for key, options of schema
      options = @_parseFieldOptions(options)

      # a relationship (defered parse)
      if _.isFunction(options)
        @relations[key] = options

      # typed field
      else if options.type
        throw new Error "Unexpected type name is not a string: #{util.inspect(options)}" unless _.isString(options.type)

        # a relationship
        switch options.type
          when 'hasOne', 'belongsTo', 'hasMany' then @relations[key] = options
          else
            options.type = type if type = Schema.types[type_name]
            @fields[key] = options

      # non-typed, eg. document
      else
        @fields[key] = options

    return

  _monkeyPatchModel: ->
    _schema = @

    _set = @model_type::set
    @model_type::set = (key, value, options) ->
      if _.isString(key)
        (attributes = {})[key] = value;
      else
        attributes = key; options = value

      for key, value of attributes
        if relation = _schema.relation(key)
          relation.set(@, key, value, options, _set)
        else
          _set.call(@, key, value, options)
      return @

    _get = @model_type::get
    @model_type::get = (key, callback) ->
      if (relation = _schema.relations[key]) or (relation = _schema.ids_accessor[key])
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

  relation: (key) ->
    return @relations[key] or @ids_accessor[key]
