util = require 'util'
_ = require 'underscore'
inflection = require 'inflection'

resolveModelType = (type) -> if _.isFunction(type) then type() else type

class Relationship
  constructor: (@model_type, @key, @options_array) ->

  initialize: ->
    @to_model_type = resolveModelType(@options_array[0])
    @[key] = value for key, value of @options_array[1]
    @foreign_key = inflection.foreign_key(@key) unless @foreign_key
    # foreign_key: options.foreign_key or @_keyFromTypeAndModel(relation_type, from_model, to_model, options.reverse)

class HasOne extends Relationship
  get: (model, callback) ->
    console.log "HasOne::get  foreign_key: #{relation.foreign_key}"

    related_model_type = @to_model_type
    query = {$one: true}

    if @reverse
      query[@foreign_key] = model.attributes.id
    else
      query.id = model.get(@foreign_key)

    related_model_type.cursor(query).toModels (err, model) ->
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not model
      callback(null, model)

class HasMany extends Relationship
  get: (model, callback) ->
    console.log "HasMany::get foreign_key: #{@foreign_key}"

    related_model_type = @to_model_type
    query = {}
    query[@foreign_key] = model.attributes.id

    related_model_type.cursor(query).toModels (err, models) ->
      return callback(err) if err
      return callback(new Error "Model not found. Id #{@foreign_key}") if not models.length
      callback(null, models)

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

  initialize: -> relation.initialize() for key, relation of @relations
  relationship: (key) -> return @relations[key]

  _parse: ->
    schema = _.result(@model_type, 'schema') or {}

    @fields ={}
    @relations ={}

    # parse
    for key, field_options of schema
      if _.isArray(field_options)
        field = field_options[0]
        options = field_options.slice(1)
        options = [options] unless _.isArray(options)

      else
        field = field_options
        options = null

      # recognized type
      if type = Schema.types[field]
        @fields[key] = type

      # relation
      else
        throw new Error "parseRelations, relation does not resolve to an array of [type, model, options]. Options: #{util.inspect(options)}" unless _.isArray(options)
        if field is 'hasOne'
          @relations[key] = new HasOne(@model_type, key, options)
        else if field is 'hasMany'
          @relations[key] = new HasMany(@model_type, key, options)
        else
          throw new Error "Unrecognized relationship type: #{field}"

  _monkeyPatchModel: ->
    _schema = @

    # TODO
    # @model_type::set = (attributes) ->

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