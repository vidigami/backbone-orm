util = require 'util'
_ = require 'underscore'
JSONUtils = require './json_utils'

module.exports = class Cursor
  constructor: (query, options) ->
    @[key] = value for key, value of options
    parsed_query = Cursor.parseQuery(query)
    @_find = parsed_query.find; @_cursor = parsed_query.cursor

    # ensure arrays
    @_cursor[key] = [@_cursor[key]] for key in ['$white_list', '$select', '$values'] when @_cursor[key] and not _.isArray(@_cursor[key])

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
      if @model_type._cache
        return callback(null, if json then @model_type._cache.findCachedOrCreate(json, @model_type) else null) if @_cursor.$one
        callback(null, @model_type._cache.findCachedOrCreate(json, @model_type))
      else
        return callback(null, if json then (new @model_type(@model_type::parse(json))) else null) if @_cursor.$one
        callback(null, (new @model_type(@model_type::parse(attributes)) for attributes in json))
    return # terminating

  count: (callback) -> return @toJSON(callback, true)