util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'

Cursor = require './cursor'

# @private
module.exports = class VirtualCursor extends Cursor
  toJSON: (callback) ->
    return callback(new Error 'Cannot perform a find on a virtual cursor') if _.size(@_find)
    return callback(new Error 'Cannot perform cursor operations on a virtual cursor') if _.size(@_cursor) and not @hasCursorQuery('$one')

    if Utils.isModel(@model)
      value = @model.get(@relation.key)
      return callback(null, if value then value.toJSON() else null) if @hasCursorQuery('$one')
      callback(null, value.toJSON())

    else
      value = @model[@relation.key]
      return callback(null, value) if @hasCursorQuery('$one')
      callback(if value then value else [])