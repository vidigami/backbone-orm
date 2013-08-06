util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
One = require './relations/one'
Many = require './relations/many'
inflection = require 'inflection'

# @private
module.exports = class Schema
  constructor: (@model_type) ->
    @raw = _.result(@model_type, 'schema') or {}
    @fields ={}; @relations ={}; @ids_accessor = {}

  initialize: ->
    return if @is_initialized; @is_initialized = true

    for key, options of @raw
      options = @_parseFieldOptions(if _.isFunction(options) then options() else options)
      (@fields[key] = options; continue) unless options.type

      type = inflection.camelize(inflection.underscore(options.type), true) # ensure HasOne, hasOne, and has_one resolve to hasOne
      switch type
        when 'hasOne', 'belongsTo', 'hasMany'
          options.type = type
          relation = @relations[key] = if (type is 'hasMany') then new Many(@model_type, key, options) else new One(@model_type, key, options)
          @ids_accessor[relation.ids_accessor] = relation if relation.ids_accessor
        else
          throw new Error "Unexpected type name is not a string: #{util.inspect(options)}" unless _.isString(options.type)
          @fields[key] = options

    # initalize in two steps to break circular dependencies
    relation.initialize() for key, relation of @relations
    return

  relation: (key) -> return @relations[key] or @ids_accessor[key]
  addRelation: (relation) ->
    @relations[relation.key] = relation
    @ids_accessor[relation.ids_accessor] = relation if relation.ids_accessor
    relation.initialize()
    return relation

  initializeModel: (model) ->
    relation.initializeModel(model, key) for key, relation of @relations

  allColumns: ->
    columns = _.keys(@fields)
    for name, relation of @relations
      columns.push(relation.foreign_key) if relation.type is 'belongsTo'
    return columns

  #################################
  # Internal
  #################################

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
