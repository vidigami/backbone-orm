util = require 'util'
_ = require 'underscore'

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

  ids: ->
    @_cursor.$values = ['id']
    return @

  ##############################################
  # Execution of the Query
  ##############################################
  count: (callback) -> @execWithCursorQuery('$count', callback)
  exists: (callback) -> @execWithCursorQuery('$count', callback)
  execWithCursorQuery: (key, callback) ->
    value = @_cursor[key]
    @_cursor[key] = true
    @toJSON (err, json) =>
      if _.isUndefined(value) then delete @_cursor[key] else (@_cursor[key] = value)
      callback(err, json)
  hasCursorQuery: (key) -> return @_cursor[key] or (@_cursor[key] is '')

  toModels: (callback) ->
    @toJSON (err, json) =>
      return callback(err) if err
      return callback(new Error "Cannot call toModels on cursor with values. Values: #{util.inspect(@_cursor.$values)}") if @_cursor.$values
      return callback(null, if json then @model_type.findOrNew(@model_type::parse(json)) else null) if @_cursor.$one
      callback(null, (@model_type.findOrNew(@model_type::parse(attributes)) for attributes in json))

  # @abstract Provided by a concrete cursor for a Backbone Sync type
  toJSON: (callback) -> throw new Error 'toJSON must be implemented by a concrete cursor for a Backbone Sync type'
