util = require 'util'
_ = require 'underscore'
JSONUtils = require './json_utils'

module.exports = class Cursor
  constructor: (@backbone_sync, query) ->
    @backbone_adapter = @backbone_sync.backbone_adapter
    @model_type = @backbone_sync.model_type
    @connection = @backbone_sync.connection

    if _.isObject(query)
      @_find = @_parseFindQuery(query)
      @_cursor = @_parseCursorQuery(query)
    else
      @_find = {id: query}
      @_cursor = {$one: true}

  offset: (offset) -> @_cursor.$offset = offset; return @
  limit: (limit) -> @_cursor.$limit = limit; return @

  whiteList: (keys) ->
    keys = [keys] unless _.isArray(keys)
    @_cursor.$white_list = if @_cursor.$white_list then _.intersection(@_cursor.$white_list, keys) else keys
    return @

  select: (keys) ->
    keys = [keys] unless _.isArray(keys)
    @_cursor.$select = if @_cursor.$select then _.intersection(@_cursor.$select, keys) else keys
    return @

  values: (keys) ->
    keys = [keys] unless _.isArray(keys)
    @_cursor.$values = if @_cursor.$values then _.intersection(@_cursor.$values, keys) else keys
    return @

  ##############################################
  # Execution of the Query
  ##############################################

  # TEMPLATE METHOD
  # toJSON: (callback) ->

  toModels: (callback) ->
    @toJSON (err, json) =>
      return callback(err) if err
      return callback(new Error "Cannot call toModels on cursor with values. Values: #{util.inspect(@_cursor.$values)}") if @_cursor.$values
      return callback(null, if json then (new @model_type(@model_type::parse(json))) else null) if @_cursor.$one
      callback(null, (new @model_type(@model_type::parse(attributes)) for attributes in json))
    return # terminating

  value: (callback) ->
    return @toModels(callback) if @_cursor.$one
    return @toJSON(callback, @_cursor.$count) if @_cursor.$count
    callback(new Error "Cursor does not refer to a single value")
    return # terminating

  count: (callback) -> return @toJSON(callback, true)

  ##############################################
  # Query Parsing
  ##############################################
  _parseFindQuery: (raw_query) ->
    find = {}
    (find[key] = JSONUtils.JSONToValue(value) if key[0] isnt '$') for key, value of raw_query
    return find

  _parseCursorQuery: (raw_query) ->
    cursor = {}
    for key, value of raw_query
      continue if key[0] isnt '$' or key is '$ids'

      switch key
        when '$limit' then cursor.$limit = parseInt(value, 10)
        when '$offset' then cursor.$offset = parseInt(value, 10)
        when '$count' then cursor.$count = true
        when '$select', '$values'
          if _.isString(value) and value.length and value[0] is '['
            cursor[key] = @_parseArray(value)
            console.log("Failed to parse $select: #{value}") unless cursor[key]
          else
            cursor[key] = JSONUtils.JSONToValue(value)
            cursor[key] = [cursor[key]] unless _.isArray(cursor[key])

        when '$ids'
          cursor[key] = @_parseArray(value)
          console.log("Failed to parse $ids: #{value}") unless cursor[key]

       # parse even if you don't recognize it so others can use it
        else
          cursor[key] = JSONUtils.JSONToValue(value)

    return cursor

  _parseArray: (value) ->
    try (array = JSON.parse(value)) catch e
    return if array and _.isArray(array) then array else undefined

  # toResponse: (results) ->
  #   if @_cursor.$count
  #     return 0 unless results
  #     return results if _.isNumber(results)
  #     return results.length if _.isArray(results)
  #     return 1

  #   if @_cursor.$limit is 1
  #     if @_cursor.$select
  #       return _.map(@_cursor.$select, (key) -> results[key]) if @_cursor.$select.length > 1
  #       return results[@_cursor.$select[0]] if @_cursor.$select[0]
  #   else
  #     if @_cursor.$select
  #       return _.map(results, (value) => _.map(@_cursor.$select, (key) -> value[key])) if @_cursor.$select.length > 1
  #       return _.pluck(results, @_cursor.$select[0]) if @_cursor.$select[0]
  #   return results
