###
  backbone-orm.js 0.5.0
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
###

_ = require 'underscore'

QueryCache = require('./cache/singletons').QueryCache
Utils = require './utils'

CURSOR_KEYS = ['$count', '$exists', '$zero', '$one', '$offset', '$limit', '$page', '$sort', '$white_list', '$select', '$include', '$values', '$ids']

module.exports = class Cursor
  # @private
  constructor: (query, options) ->
    @[key] = value for key, value of options
    parsed_query = Cursor.parseQuery(query, @model_type)
    @_find = parsed_query.find; @_cursor = parsed_query.cursor

    # ensure arrays
    @_cursor[key] = [@_cursor[key]] for key in ['$white_list', '$select', '$values'] when @_cursor[key] and not _.isArray(@_cursor[key])

  # @private
  @validateQuery = (query, memo, model_type) =>
    for key, value of query
      continue unless _.isUndefined(value) or _.isObject(value)
      full_key = if memo then "#{memo}.#{key}" else key
      throw new Error "Unexpected undefined for query key '#{full_key}' on #{model_type?.model_name}" if _.isUndefined(value)
      @validateQuery(value, full_key, model_type) if _.isObject(value)

  # @private
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
    @_cursor.$white_list = if @_cursor.$white_list then _.intersection(@_cursor.$white_list, keys) else keys
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

  ids: -> @_cursor.$values = ['id']; return @

  ##############################################
  # Execution of the Query

  count: (callback) -> @execWithCursorQuery('$count', 'toJSON', callback)
  exists: (callback) -> @execWithCursorQuery('$exists', 'toJSON', callback)
  toModel: (callback) -> @execWithCursorQuery('$one', 'toModels', callback)
  toModels: (callback) ->
    return callback(new Error "Cannot call toModels on cursor with values for model #{@model_type.model_name}. Values: #{Utils.inspect(@_cursor.$values)}") if @_cursor.$values

    # a cache candidate
    # if not (@_cursor.$offset or @_cursor.$limit or @_cursor.$include) and cache = @model_type.cache
    #   find_size = _.size(@_find)
    #   if find_size is 0
    #     return callback(null, model) if not (ids = @_cursor.$ids) and @_cursor.$one and (model = cache.get())

    #   else if find_size is 1 and @_find.id
    #     if not (ids = @_find.id.$in) and (model = cache.get(@_find.id))
    #       return callback(null, if @_cursor.$one then model else [model])

    #   if ids
    #     missing_ids = [] # TODO: fetch delta ids, need to handle sorting, etc
    #     models = []
    #     for id in ids
    #       (missing_ids.push(id); continue) unless model = cache.get(id)
    #       models.push(model)
    #       break if @_cursor.$one

    #     if @_cursor.$one
    #       return callback(null, models[0]) if models.length
    #     else
    #       if not missing_ids.length # found everything
    #         if @_cursor.$sort
    #           $sort_fields = if _.isArray(@_cursor.$sort) then @_cursor.$sort else [@_cursor.$sort]
    #           models.sort (model, next_model) => return Utils.jsonFieldCompare(model.attributes, next_model.attributes, $sort_fields)
    #         return callback(null, models)

    @toJSON (err, json) =>
      return callback(err) if err
      return callback(null, null) if @_cursor.$one and not json
      json = [json] unless _.isArray(json)

      @prepareIncludes json, (err, json) =>
        if can_cache = !(@_cursor.$select or @_cursor.$whitelist) # don't cache if we may not have fetched the full model
          models = (Utils.updateOrNew(item, @model_type) for item in json)
        else
          models = (model = new @model_type(@model_type::parse(item)); model.setPartial(true); model for item in json)
        return callback(null, if @_cursor.$one then models[0] else models)

  toJSON: (callback) ->
    parsed_query = _.extend({}, _.pick(@_cursor, CURSOR_KEYS), @_find)
    # Check query cache
    QueryCache.get @model_type, parsed_query, (err, cached_result) =>
      return callback(err) if err
      return callback(null, cached_result) unless _.isUndefined(cached_result)

      model_types = @relatedModelTypesInQuery()
      @queryToJSON (err, json) =>
        return callback(err) if err
        unless _.isNull(json)
          QueryCache.set @model_type, parsed_query, model_types, json, (err) ->
            console.log "Error setting query cache: #{err}" if err # TODO: Update query cache, ignore errors
            callback(null, json)
        else
          callback(null, json)

  # @private
  # Provided by a concrete cursor for a Backbone Sync type
  queryToJSON: (callback) ->
    throw new Error 'toJSON must be implemented by a concrete cursor for a Backbone Sync type'

  ##############################################
  # Helpers
  ##############################################

  # @private
  hasCursorQuery: (key) -> return @_cursor[key] or (@_cursor[key] is '')

  # @private
  execWithCursorQuery: (key, method, callback) ->
    value = @_cursor[key]
    @_cursor[key] = true
    @[method] (err, json) =>
      if _.isUndefined(value) then delete @_cursor[key] else (@_cursor[key] = value)
      callback(err, json)

  # @private
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

  # @private
  selectResults: (json) ->
    # TODO: OPTIMIZE TO REMOVE 'id' and '_rev' if needed
    if @_cursor.$values
      $values = if @_cursor.$white_list then _.intersection(@_cursor.$values, @_cursor.$white_list) else @_cursor.$values
      if @_cursor.$values.length is 1
        key = @_cursor.$values[0]
        json = if $values.length then ((if item.hasOwnProperty(key) then item[key] else null) for item in json) else _.map(json, -> null)
      else
        json = (((item[key] for key in $values when item.hasOwnProperty(key))) for item in json)

    else if @_cursor.$select
      $select = if @_cursor.$white_list then _.intersection(@_cursor.$select, @_cursor.$white_list) else @_cursor.$select
      json = (_.pick(item, $select) for item in json)

    else if @_cursor.$white_list
      json = (_.pick(item, @_cursor.$white_list) for item in json)

    return if @_cursor.$one then (json[0] or null) else json

  # @private
  selectFromModels: (models, callback) ->
    if @_cursor.$select
      $select = if @_cursor.$white_list then _.intersection(@_cursor.$select, @_cursor.$white_list) else @_cursor.$select
      models = (model = new @model_type(_.pick(model.attributes, $select)); model.setPartial(true); model for item in models)

    else if @_cursor.$white_list
      models = (model = new @model_type(_.pick(model.attributes, @_cursor.$white_list)); model.setPartial(true); model for item in models)

    return models

  # @private
  prepareIncludes: (json, callback) ->
    return callback(null, json) if not _.isArray(@_cursor.$include) or _.isEmpty(@_cursor.$include)
    schema = @model_type.schema()
    shared_related_models = {}

    findOrNew = (related_json, reverse_model_type) =>
      unless shared_related_models[related_json.id]
        if reverse_model_type.cache
          unless shared_related_models[related_json.id] = reverse_model_type.cache.get(related_json.id)
            reverse_model_type.cache.set(related_json.id, shared_related_models[related_json.id] = new reverse_model_type(related_json))
        else
          shared_related_models[related_json.id] = new reverse_model_type(related_json)
      return shared_related_models[related_json.id]

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
