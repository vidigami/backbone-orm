util = require 'util'
_ = require 'underscore'

Cursor = require './cursor'
Cache = require './cache'

# @private
module.exports = class CacheCursor extends Cursor
  toJSON: (callback) ->
    @wrapped_sync_fn('cursor', _.extend(_.extend({}, @_find), @_cursor)).toJSON (err, json) =>
      return callback(err) if err
      Cache.set(@model_type.name, json) # add to cache
      callback(null, json)
