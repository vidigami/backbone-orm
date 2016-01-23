###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'

Utils = require './utils'
JSONUtils = require './json_utils'

CURSOR_KEYS = ['$count', '$exists', '$zero', '$one', '$offset', '$limit', '$page', '$sort', '$unique', '$whitelist', '$select', '$include', '$values', '$ids', '$or']

module.exports = class Cursor
  # @nodoc
  constructor: (query, options) ->
    @[key] = value for key, value of options
    parsed_query = Cursor.parseQuery(query, @model_type)
    @_find = parsed_query.find; @_cursor = parsed_query.cursor

    # ensure arrays
    @_cursor[key] = [@_cursor[key]] for key in ['$whitelist', '$select', '$values', '$unique'] when @_cursor[key] and not _.isArray(@_cursor[key])

  # @nodoc
  @validateQuery = (query, memo, model_type) =>
    for key, value of query
      continue unless _.isUndefined(value) or _.isObject(value)
      full_key = if memo then "#{memo}.#{key}" else key
      throw new Error "Unexpected undefined for query key '#{full_key}' on #{model_type?.model_name}" if _.isUndefined(value)
      @validateQuery(value, full_key, model_type) if _.isObject(value)

  # @nodoc
  @parseQuery: (query, model_type) =>
    if not query
      return {find: {}, cursor: {}}
    else if not _.isObject(query)
      return {find: {id: query}, cursor: {$one: true}}
    else if query.find or query.cursor
      return {find: query.find or {}, cursor: query.cursor or {}}
    else
      try
        @validateQuery(query, null, model_type)
      catch e
        throw new Error "Error: #{e}. Query: ", query
      parsed_query = {find: {}, cursor: {}}
      for key, value of query
        if key[0] isnt '$' then (parsed_query.find[key] = value) else (parsed_query.cursor[key] = value)
      return parsed_query

  offset: (offset) -> @_cursor.$offset = offset; return @
  limit: (limit) -> @_cursor.$limit = limit; return @
  sort: (sort) -> @_cursor.$sort = sort; return @

  whiteList: (args) ->
    keys = _.flatten(arguments)
    @_cursor.$whitelist = if @_cursor.$whitelist then _.intersection(@_cursor.$whitelist, keys) else keys
    return @

  select: (args) ->
    keys = _.flatten(arguments)
    @_cursor.$select = if @_cursor.$select then _.intersection(@_cursor.$select, keys) else keys
    return @

  include: (args) ->
    keys = _.flatten(arguments)
    @_cursor.$include = if @_cursor.$include then _.intersection(@_cursor.$include, keys) else keys
    return @

  values: (args) ->
    keys = _.flatten(arguments)
    @_cursor.$values = if @_cursor.$values then _.intersection(@_cursor.$values, keys) else keys
    return @

  unique: (args) ->
    keys = _.flatten(arguments)
    @_cursor.$unique = if @_cursor.$unique then _.intersection(@_cursor.$unique, keys) else keys
    return @

  # @nodoc
  ids: -> @_cursor.$values = ['id']; return @

  ##############################################
  # Execution of the Query

  count: (callback) -> @execWithCursorQuery('$count', 'toJSON', callback)
  exists: (callback) -> @execWithCursorQuery('$exists', 'toJSON', callback)
  toModel: (callback) -> @execWithCursorQuery('$one', 'toModels', callback)
  toModels: (callback) ->
    return callback(new Error "Cannot call toModels on cursor with values for model #{@model_type.model_name}. Values: #{JSONUtils.stringify(@_cursor.$values)}") if @_cursor.$values

    @toJSON (err, json) =>
      return callback(err) if err
      return callback(null, null) if @_cursor.$one and not json
      json = [json] unless _.isArray(json)

      @prepareIncludes json, (err, json) =>
        if can_cache = !(@_cursor.$select or @_cursor.$whitelist) # don't cache if we may not have fetched the full model
          models = (Utils.updateOrNew(item, @model_type) for item in json)
        else
          models = ((model = new @model_type(@model_type::parse(item)); model.setPartial(true); model) for item in json)
        return callback(null, if @_cursor.$one then models[0] else models)

  toJSON: (callback) -> @queryToJSON(callback)

  # @nodoc
  # Provided by a concrete cursor for a Backbone Sync type
  queryToJSON: (callback) -> throw new Error 'queryToJSON must be implemented by a concrete cursor for a Backbone Sync type'

  ##############################################
  # Helpers
  ##############################################

  # @nodoc
  hasCursorQuery: (key) -> return @_cursor[key] or (@_cursor[key] is '')

  # @nodoc
  execWithCursorQuery: (key, method, callback) ->
    value = @_cursor[key]
    @_cursor[key] = true
    @[method] (err, json) =>
      if _.isUndefined(value) then delete @_cursor[key] else (@_cursor[key] = value)
      callback(err, json)

  # @nodoc
  relatedModelTypesInQuery: =>
    related_fields = []
    related_model_types = []

    for key, value of @_find

      # A dot indicates a condition on a related model
      if key.indexOf('.') > 0
        [relation_key, key] = key.split('.')
        related_fields.push(relation_key)

      # Many to Many relationships may be queried on the foreign key of the join table
      else if (reverse_relation = @model_type.reverseRelation(key)) and reverse_relation.join_table
        related_model_types.push(reverse_relation.model_type)
        related_model_types.push(reverse_relation.join_table)

    related_fields = related_fields.concat(@_cursor.$include) if @_cursor?.$include
    for relation_key in related_fields
      if relation = @model_type.relation(relation_key)
        related_model_types.push(relation.reverse_model_type)
        related_model_types.push(relation.join_table) if relation.join_table

    return related_model_types

  # @nodoc
  selectResults: (json) ->
    json = json.slice(0, 1) if @_cursor.$one

    # TODO: OPTIMIZE TO REMOVE 'id' and '_rev' if needed
    if @_cursor.$values
      $values = if @_cursor.$whitelist then _.intersection(@_cursor.$values, @_cursor.$whitelist) else @_cursor.$values
      if @_cursor.$values.length is 1
        key = @_cursor.$values[0]
        json = if $values.length then ((if item.hasOwnProperty(key) then item[key] else null) for item in json) else _.map(json, -> null)
      else
        json = (((item[key] for key in $values when item.hasOwnProperty(key))) for item in json)

    else if @_cursor.$select
      $select = if @_cursor.$whitelist then _.intersection(@_cursor.$select, @_cursor.$whitelist) else @_cursor.$select
      json = (_.pick(item, $select) for item in json)

    else if @_cursor.$whitelist
      json = (_.pick(item, @_cursor.$whitelist) for item in json)

    return json if @hasCursorQuery('$page') # paging expects an array
    return if @_cursor.$one then (json[0] or null) else json

  # @nodoc
  selectFromModels: (models, callback) ->
    if @_cursor.$select
      $select = if @_cursor.$whitelist then _.intersection(@_cursor.$select, @_cursor.$whitelist) else @_cursor.$select
      models = (model = new @model_type(_.pick(model.attributes, $select)); model.setPartial(true); model for item in models)

    else if @_cursor.$whitelist
      models = (model = new @model_type(_.pick(model.attributes, @_cursor.$whitelist)); model.setPartial(true); model for item in models)

    return models

  # @nodoc
  prepareIncludes: (json, callback) ->
    return callback(null, json) if not _.isArray(@_cursor.$include) or _.isEmpty(@_cursor.$include)
    schema = @model_type.schema()
    shared_related_models = {}

    findOrNew = (related_json, reverse_model_type) =>
      related_id = related_json[reverse_model_type::idAttribute]
      unless shared_related_models[related_id]
        if reverse_model_type.cache
          unless shared_related_models[related_id] = reverse_model_type.cache.get(related_id)
            reverse_model_type.cache.set(related_id, shared_related_models[related_id] = new reverse_model_type(related_json))
        else
          shared_related_models[related_id] = new reverse_model_type(related_json)
      return shared_related_models[related_id]

    for include in @_cursor.$include
      relation = schema.relation(include)
      shared_related_models = {} # reset

      for model_json in json
        # many
        if _.isArray(related_json = model_json[include])
          model_json[include] = (findOrNew(item, relation.reverse_model_type) for item in related_json)

        # one
        else if related_json
          model_json[include] = findOrNew(related_json, relation.reverse_model_type)

    callback(null, json)
