util = require 'util'
_ = require 'underscore'

Cursor = require './cursor'
Cache = require './cache'

# @private
module.exports = class CacheCursor extends Cursor
  toJSON: (callback) ->
    @wrapped_sync_fn('cursor', query = _.extend(_.extend({}, @_find), @_cursor)).toJSON (err, json) =>
      return callback(err) if err
      Cache.getOrCreate(@model_type.model_name, @model_type, json) if not (@_cursor.$values or @_cursor.$select) # update cache if was a full fetch
      callback(null, json)
