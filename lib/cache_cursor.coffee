util = require 'util'
_ = require 'underscore'

Cursor = require './cursor'
Utils = require './utils'

# @private
module.exports = class CacheCursor extends Cursor
  toJSON: (callback) ->
    @wrapped_sync_fn('cursor', query = _.extend(_.extend({}, @_find), @_cursor)).toJSON (err, json) =>
      return callback(err) if err
      if json and not (@_cursor.$values or @_cursor.$select) # update cache if was a full fetch
        data = if _.isArray(json) then json else [json]
        Utils.updateOrNew(item, @model_type) for item in data
      callback(null, json)
