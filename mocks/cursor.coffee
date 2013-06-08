util = require 'util'
_ = require 'underscore'

Cursor = require '../cursor'

module.exports = class MockCursor extends Cursor
  constructor: (sync, query, @json) -> super

  toJSON: (callback, count) ->
    if (keys = _.keys(@_find)).length
      json = _.select(@json, (item) => _.isEqual(_.pick(item, keys), @_find))
    else
      json = _.clone(@json)

    # find.order = @_cursor.$sort if @_cursor.$sort # TODO: should be in form {order: 'title DESC'}
    json.splice(@_cursor.$offset, json.length) if @_cursor.$offset
    if @_cursor.$one
      json = [json[0]]
    else if @_cursor.$limit
      json = json.splice(0, @_cursor.$limit)
    # args._id = {$in: _.map(ids, (id) -> new ObjectID("#{id}"))} if @_cursor.$ids # TODO

    return callback(null, json.length) if count or @_cursor.$count # only the count

    # only select specific fields
    if @_cursor.$values
      $fields = if @_cursor.$white_list then _.intersection(@_cursor.$values, @_cursor.$white_list) else @_cursor.$values
    else if @_cursor.$select
      $fields = if @_cursor.$white_list then _.intersection(@_cursor.$select, @_cursor.$white_list) else @_cursor.$select
    else if @_cursor.$white_list
      $fields = @_cursor.$white_list
    json = _.map(json, (item) -> _.pick(item, $fields)) if $fields

    return callback(null, if json.length then json[0] else null) if @_cursor.$one

    # TODO: OPTIMIZE TO REMOVE 'id' and '_rev' if needed
    if @_cursor.$values
      $values = if @_cursor.$white_list then _.intersection(@_cursor.$values, @_cursor.$white_list) else @_cursor.$values
      json = (((item[key] for key in $values when item.hasOwnProperty(key))) for item in json)
    else if @_cursor.$select
      $select = if @_cursor.$white_list then _.intersection(@_cursor.$select, @_cursor.$white_list) else @_cursor.$select
      json = _.map(json, (item) => _.pick(item, $select))
    else if @_cursor.$white_list
      json = _.map(json, (item) => _.pick(item, @_cursor.$white_list))
    callback(null, json)
    return # terminating
