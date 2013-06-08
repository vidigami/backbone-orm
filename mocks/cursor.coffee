util = require 'util'
_ = require 'underscore'

module.exports = class MockCursor
  constructor: (query, @json) ->
    @queries = @_parseQueries(query)
    @[key] = value for key, value of @queries

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

  toJSON: (callback) ->
    if @_cursor.$values
      $values = if @_cursor.$white_list then _.intersection(@_cursor.$values, @_cursor.$white_list) else @_cursor.$values
      json = (((item[key] for key in $values when item.hasOwnProperty(key))) for item in @json)
    else if @_cursor.$select
      $select = if @_cursor.$white_list then _.intersection(@_cursor.$select, @_cursor.$white_list) else @_cursor.$select
      json = _.map(@json, (item) => _.pick(item, $select))
    else if @_cursor.$white_list
      json = _.map(@json, (item) => _.pick(item, @_cursor.$white_list))
    else
      json = @json

    return callback(null, json[0]) if @_cursor.$one
    callback(null, json)
    return # terminating

  _parseQueries: (query) ->
    queries = {_find: {}, _cursor: {}}
    (query = {id: query}; queries._cursor.$one = true) unless _.isObject(query)
    for key, value of query
      if key[0] is '$'
        if key is '$select' or key is '$values'
          queries._cursor[key] = if _.isArray(value) then value else [value]
        else
          queries._cursor[key] = value
      else
        queries._find[key] = value
    return queries