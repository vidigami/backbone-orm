###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
Backbone = require 'backbone'

BackboneORM = require '../core'
One = require '../relations/one'
Many = require '../relations/many'
DatabaseURL = require './database_url'
Utils = require './utils'
JSONUtils = require './json_utils'

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
  constructor: (@model_type, @type_overrides={}) ->
    @raw = _.clone(_.result(new @model_type(), 'schema') or {})
    @fields = {}; @relations = {}; @virtual_accessors = {}
    @_parseField('id', @raw.id) if @raw.id

  # @nodoc
  initialize: ->
    return if @is_initialized; @is_initialized = true

    # initalize in two steps to break circular dependencies
    @_parseField(key, info) for key, info of @raw
    relation.initialize() for key, relation of @relations
    return

  type: (key, type) ->
    ((@type_overrides[key] or= {})['type'] = type; return @) if arguments.length is 2
    (other = key.substr(index+1); key = key.substr(0, index)) if (index = key.indexOf('.')) >= 0 # queries like 'flat.id'
    return unless type = @type_overrides[key]?.type or @fields[key]?.type or @relation(key)?.reverse_model_type or @reverseRelation(key)?.model_type
    if @virtual_accessors[key]
      (console.log "Unexpected other for virtual id key: #{key}.#{other}"; return) if other
      return type.schema?().type('id') or type
    return if other then type.schema?().type(other) else type

  idType: (key) ->
    return @type('id') unless key
    return type.schema?().type('id') or type if type = @type(key)

  field: (key) -> return @fields[key] or @relation(key)
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
    key = BackboneORM.naming_conventions.attribute(reverse_model_type.model_name)
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
    table_name1 = BackboneORM.naming_conventions.tableName(relation.model_type.model_name)
    table_name2 = BackboneORM.naming_conventions.tableName(relation.reverse_relation.model_type.model_name)
    return if table_name1.localeCompare(table_name2) < 0 then "#{table_name1}_#{table_name2}" else "#{table_name2}_#{table_name1}"

  # @nodoc
  generateJoinTable: (relation) ->
    schema = {}
    schema[relation.join_key] = [type = relation.model_type.schema().type('id'), indexed: true]
    schema[relation.reverse_relation.join_key] = [relation.reverse_model_type?.schema().type('id') or type, indexed: true]
    url = Schema.joinTableURL(relation)
    name = BackboneORM.naming_conventions.modelName(url, true)

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
      throw new Error "Unexpected type name is not a string: #{JSONUtils.stringify(options)}" unless _.isString(options.type)
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
    throw new Error "Unexpected field options array: #{JSONUtils.stringify(options)}" if options.length > 1

    # options object
    _.extend(result, options[0]) if options.length is 1
    return result
