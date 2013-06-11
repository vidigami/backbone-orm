util = require 'util'
_ = require 'underscore'

Helpers = require '../lib/test_helpers'
Cursor = require '../cursor'

module.exports = class MockCursor extends Cursor
  toJSON: (callback, count) ->
    if (keys = _.keys(@_find)).length
      json = []
      for id, model of @model_type._sync.store
        json.push(model.attributes) if _.isEqual(_.pick(model.attributes, keys), @_find)
    else
      json = (model.attributes for id, model of @model_type._sync.store)

    # find.order = @_cursor.$sort if @_cursor.$sort # TODO: should be in form {order: 'title DESC'}
    if @_cursor.$offset
      number = json.length - @_cursor.$offset
      number = 0 if number < 0
      json = if number then json.slice(@_cursor.$offset, @_cursor.$offset+number) else []

    if @_cursor.$one
      json = if json.length then [json[0]] else []
    else if @_cursor.$limit
      json = json.splice(0, Math.min(json.length, @_cursor.$limit))
    # args._id = {$in: _.map(ids, (id) -> new ObjectID("#{id}"))} if @_cursor.$ids # TODO

    return callback(null, json.length) if count or @_cursor.$count # only the count

    if @_cursor.$sort and Array.isArray(json)
      $sort_fields = if Array.isArray(@_cursor.$sort) then @_cursor.$sort else [@_cursor.$sort]
      json.sort (model, next_model) => return Helpers.jsonFieldCompare(model, next_model, $sort_fields)

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

    callback(null, json)
    return # terminating
