###
  backbone-orm.js 0.5.16
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

_ = require 'underscore'
Backbone = require 'backbone'
inflection = require 'inflection'

One = require './relations/one'
Many = require './relations/many'
DatabaseURL = require './database_url'
Utils = require './utils'

RELATION_VARIANTS =
  'hasOne': 'hasOne'
  'has_one': 'hasOne'
  'HasOne': 'hasOne'

  'belongsTo': 'belongsTo'
  'belongs_to': 'belongsTo'
  'BelongsTo': 'belongsTo'

  'hasMany': 'hasMany'
  'has_many': 'hasMany'
  'HasMany': 'hasMany'

# @private
module.exports = class Schema
  # @nodoc
  constructor: (@model_type) ->
    @raw = _.clone(_.result(new @model_type(), 'schema') or {})
    @fields ={}; @relations ={}; @virtual_accessors = {}

  # @nodoc
  initialize: ->
    return if @is_initialized; @is_initialized = true

    # initalize in two steps to break circular dependencies
    @_parseField(key, info) for key, info of @raw
    relation.initialize() for key, relation of @relations
    return

  relation: (key) -> return @relations[key] or @virtual_accessors[key]
  reverseRelation: (reverse_key) ->
    return relation.reverse_relation for key, relation of @relations when relation.reverse_relation and (relation.reverse_relation.join_key is reverse_key)
    return null

  # column and relationship helpers
  columns: ->
    columns = _.keys(@fields)
    columns.push('id') if not _.find(columns, (column) -> column is 'id')
    columns.push(relation.foreign_key) for key, relation of @relations when (relation.type is 'belongsTo') and not relation.isVirtual() and not relation.isEmbedded()
    return columns

  joinTables: ->
    return (relation.join_table for key, relation of @relations when not relation.isVirtual() and relation.join_table)

  relatedModels: ->
    related_model_types = []
    for key, relation of @relations
      related_model_types.push(relation.reverse_model_type)
      related_model_types.push(relation.join_table) if relation.join_table
    return related_model_types

  # TO DEPRECATE
  allColumns: -> @columns()
  allRelations: -> @relatedModels()

  # @nodoc
  generateBelongsTo: (reverse_model_type) ->
    key = inflection.underscore(reverse_model_type.model_name)
    return relation if relation = @relations[key] # already exists

    if @raw[key] # not intitialized yet, intialize now
      relation = @_parseField(key, @raw[key])
      relation.initialize()
      return relation

    # generate new
    relation = @_parseField(key, @raw[key] = ['belongsTo', reverse_model_type, manual_fetch: true])
    relation.initialize()
    return relation

  @joinTableURL: (relation) ->
    model_name1 = inflection.pluralize(inflection.underscore(relation.model_type.model_name))
    model_name2 = inflection.pluralize(inflection.underscore(relation.reverse_relation.model_type.model_name))
    return if model_name1.localeCompare(model_name2) < 0 then "#{model_name1}_#{model_name2}" else "#{model_name2}_#{model_name1}"

  # @nodoc
  generateJoinTable: (relation) ->
    schema = {}
    schema[relation.join_key] = ['Integer', indexed: true]
    schema[relation.reverse_relation.join_key] = ['Integer', indexed: true]
    url = Schema.joinTableURL(relation)
    name = inflection.pluralize(inflection.classify(url))

    try
      # @nodoc
      class JoinTable extends Backbone.Model
        model_name: name
        urlRoot: "#{(new DatabaseURL(_.result(new relation.model_type, 'url'))).format({exclude_table: true})}/#{url}"
        schema: schema
        sync: relation.model_type.createSync(JoinTable)
    catch
      # @nodoc
      class JoinTable extends Backbone.Model
        model_name: name
        urlRoot: "/#{url}"
        schema: schema
        sync: relation.model_type.createSync(JoinTable)

    return JoinTable

  # Internal

  # @nodoc
  _parseField: (key, info) ->
    options = @_fieldInfoToOptions(if _.isFunction(info) then info() else info)
    return @fields[key] = options unless options.type

    # unrecognized
    unless type = RELATION_VARIANTS[options.type]
      throw new Error "Unexpected type name is not a string: #{Utils.toString(options)}" unless _.isString(options.type)
      return @fields[key] = options

    options.type = type
    relation = @relations[key] = if type is 'hasMany' then new Many(@model_type, key, options) else new One(@model_type, key, options)
    @virtual_accessors[relation.virtual_id_accessor] = relation if relation.virtual_id_accessor
    @virtual_accessors[relation.foreign_key] = relation if type is 'belongsTo'
    return relation

  # @nodoc
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
    throw new Error "Unexpected field options array: #{Utils.toString(options)}" if options.length > 1

    # options object
    _.extend(result, options[0]) if options.length is 1
    return result
