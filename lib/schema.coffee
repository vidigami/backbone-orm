util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
One = require './relations/one'
Many = require './relations/many'
inflection = require 'inflection'
Utils = require './utils'

# @private
module.exports = class Schema
  constructor: (@model_type) ->
    @raw = _.clone(_.result(@model_type, 'schema') or {})
    @fields ={}; @relations ={}; @ids_accessor = {}

  initialize: ->
    return if @is_initialized; @is_initialized = true

    # initalize in two steps to break circular dependencies
    @_parseField(key, info) for key, info of @raw
    relation.initialize() for key, relation of @relations
    return

  relation: (key) -> return @relations[key] or @ids_accessor[key]
  reverseRelation: (reverse_key) ->
    return relation.reverse_relation for key, relation of @relations when relation.reverse_relation and (relation.reverse_relation.foreign_key is reverse_key)
    return null

  generateBelongsTo: (reverse_model_type) ->
    key = inflection.underscore(reverse_model_type.model_name)
    return relation if relation = @relations[key] # already exists

    if @raw[key] # not intitialized yet, intialize now
      relation = @_parseField(key, @raw[key])
      relation.initialize()
      return relation

    # generate new
    relation = @_parseField(key, @raw[key] = ['belongsTo', reverse_model_type, virtual: true])
    relation.initialize()
    return relation

  @joinTableURL: (relation) ->
    model_name1 = inflection.pluralize(inflection.underscore(relation.model_type.model_name))
    model_name2 = inflection.pluralize(inflection.underscore(relation.reverse_relation.model_type.model_name))
    return if model_name1.localeCompare(model_name2) < 0 then "#{model_name1}_#{model_name2}" else "#{model_name2}_#{model_name1}"

  generateJoinTable: (relation) ->
    schema = {}
    schema[relation.join_key] = ['Integer', indexed: true]
    schema[relation.reverse_relation.join_key] = ['Integer', indexed: true]
    url = Schema.joinTableURL(relation)
    name = inflection.pluralize(inflection.classify(url))

    try
      class JoinTable extends Backbone.Model
        @model_name: name
        urlRoot: "#{Utils.parseUrl(_.result(relation.model_type.prototype, 'url')).database_path}/#{url}"
        @schema: schema
        sync: relation.model_type.createSync(JoinTable)
    catch
      class JoinTable extends Backbone.Model
        @model_name: name
        urlRoot: "/#{url}"
        @schema: schema
        sync: relation.model_type.createSync(JoinTable)

    return JoinTable

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

  _parseField: (key, info) ->
    options = @_fieldInfoToOptions(if _.isFunction(info) then info() else info)
    return @fields[key] = options unless options.type

    type = inflection.camelize(inflection.underscore(options.type), true) # ensure HasOne, hasOne, and has_one resolve to hasOne
    switch type
      when 'hasOne', 'belongsTo', 'hasMany'
        options.type = type
        relation = @relations[key] = if type is 'hasMany' then new Many(@model_type, key, options) else new One(@model_type, key, options)
        @ids_accessor[relation.ids_accessor] = relation if relation.ids_accessor
        return relation
      else
        throw new Error "Unexpected type name is not a string: #{util.inspect(options)}" unless _.isString(options.type)
        return @fields[key] = options

  _fieldInfoToOptions: (options) ->
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
