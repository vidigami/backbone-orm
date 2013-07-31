util = require 'util'
_ = require 'underscore'
Queue = require 'queue-async'

Utils = require './utils'
Cursor = require './cursor'

# @private
module.exports = class CacheCursor extends Cursor
  toJSON: (callback, count) ->
    # build query
    query = _.extend(_.extend({}, @_find), @_cursor)

    # TODO: invalidate the cache
    @wrapped_sync_fn('cursor', query).toJSON(callback, count)