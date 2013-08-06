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
      return callback(null, if json then Utils.updateOrNew(json, @model_type) else null) if @_cursor.$one
      callback(null, (Utils.updateOrNew(attributes, @model_type) for attributes in json))

  # @abstract Provided by a concrete cursor for a Backbone Sync type
  toJSON: (callback) -> throw new Error 'toJSON must be implemented by a concrete cursor for a Backbone Sync type'

  ##############################################
  # Helpers
  ##############################################
  selectResults: (json, callback) ->
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
      json = _.map(json, (item) => _.pick(item, $select))

    else if @_cursor.$white_list
      json = _.map(json, (item) => _.pick(item, @_cursor.$white_list))
    return json
