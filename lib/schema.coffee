util = require 'util'
_ = require 'underscore'

HasOne = require './has_one'
HasMany = require './has_many'

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
        @relations[key] = new HasOne(@model_type, key, options.slice(1))
      else if type_name is 'hasMany'
        @relations[key] = new HasMany(@model_type, key, options.slice(1))
      else
        throw new Error "Unrecognized relationship: #{util.inspect(options)}"

  relationship: (key) -> return @relations[key]

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
        if relation = _schema.relationship(key)
          relation.set(@, key, value, options, _set)
        else
          _set.call(@, key, value, options)
      return @

    _get = @model_type::get
    @model_type::get = (key, callback) ->
      if arguments.length > 1
        if relation = _schema.relationship(key)
          relation.get(@, callback)
        else
          callback(null, @attributes[key])
      return _get.apply(@, arguments)

    @model_type::toJSON = ->
      return @get('id') if @_locked > 0
      @_locked or= 0
      @_locked++

      json = _.clone(@attributes)
      for key, value of json
        continue unless value
        if value.toJSON
          json[key] = value.toJSON()
        else if _.isArray(value)
          json[key] = _.map(value, (item) -> if item.toJSON then item.toJSON() else item)

      @_locked--
      return json