util = require 'util'
_ = require 'underscore'

Utils = require './utils'

module.exports = class Cursor
  # @private
  constructor: (query, options) ->
    @[key] = value for key, value of options
    parsed_query = Cursor.parseQuery(query)
    @_find = parsed_query.find; @_cursor = parsed_query.cursor

    # ensure arrays
    @_cursor[key] = [@_cursor[key]] for key in ['$white_list', '$select', '$values'] when @_cursor[key] and not _.isArray(@_cursor[key])

  # @private
  @parseQuery: (query) ->
    if not query
      return {find: {}, cursor: {}}
    else if not _.isObject(query)
      return {find: {id: query}, cursor: {$one: true}}
    else if query.find or query.cursor
      return {find: query.find or {}, cursor: query.cursor or {}}
    else
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
  ##############################################
  count: (callback) -> @execWithCursorQuery('$count', callback)
  exists: (callback) -> @execWithCursorQuery('$exists', callback)
  execWithCursorQuery: (key, callback) ->
    value = @_cursor[key]
    @_cursor[key] = true
    @toJSON (err, json) =>
      if _.isUndefined(value) then delete @_cursor[key] else (@_cursor[key] = value)
      callback(err, json)
  hasCursorQuery: (key) -> return @_cursor[key] or (@_cursor[key] is '')

  toModels: (callback) ->
    return callback(new Error "Cannot call toModels on cursor with values for model #{@model_type.model_name}. Values: #{util.inspect(@_cursor.$values)}") if @_cursor.$values

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
      if can_cache = !(@_cursor.$select or @_cursor.$whitelist) # don't cache if we may not have fetched the full model
        models = (Utils.updateOrNew(item, @model_type) for item in json)
      else
        models = (model = new @model_type(@model_type::parse(item)); model.setLoaded(false); model for item in json)

      @lookupIncludes models, (err, models) =>
        return callback(err) if err
        return callback(null, if @_cursor.$one then models[0] else models)

  # @abstract Provided by a concrete cursor for a Backbone Sync type
  toJSON: (callback) -> throw new Error 'toJSON must be implemented by a concrete cursor for a Backbone Sync type'

  ##############################################
  # Helpers
  ##############################################
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

    return json

  selectFromModels: (models, callback) ->
    if @_cursor.$select
      $select = if @_cursor.$white_list then _.intersection(@_cursor.$select, @_cursor.$white_list) else @_cursor.$select
      models = (model = new @model_type(_.pick(model.attributes, $select)); model.setLoaded(false); model for item in models)

    else if @_cursor.$white_list
      models = (model = new @model_type(_.pick(model.attributes, @_cursor.$white_list)); model.setLoaded(false); model for item in models)

    return models

  lookupIncludes: (models, callback) ->
    return callback(null, models) if not _.isArray(@_cursor.$include) or _.isEmpty(@_cursor.$include)
    schema = @model_type.schema()

    for include in @_cursor.$include
      relation = schema.relation(include)

      for model in models
        continue if _.isNull(related_models = model.get(include)) # nothing to bind
        return callback(new Error "toModels lookupIncludes: could not find include '#{include}' for model #{@model_type.model_name}") if _.isUndefined(related_models) # nothing to bind

        related_models = related_models.models or [related_models]
        for related_model in related_models
          return callback(new Error "toModels lookupIncludes: expecting to find reverse model for #{model.id}") unless reverse_related_models = related_model.get(relation.reverse_relation.key)

          # collection
          if reverse_related_models.models
            return callback(new Error "toModels lookupIncludes: Couldn't find model #{model.id}.") unless reverse_related_model = reverse_related_models.get(model.id)
            reverse_related_models.models.splice(reverse_related_models.models.indexOf(reverse_related_model), 1, model) # no one is listening yet

          # model
          else
            return callback(new Error "toModels lookupIncludes: Unexpected model. Expecting: #{model.id}. Found: #{related_models.id}") if reverse_related_models.id isnt model.id
            related_model.attributes[relation.reverse_relation.key] = model # no one is listening yet

    callback(null, models)
