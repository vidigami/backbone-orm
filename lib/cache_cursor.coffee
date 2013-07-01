util = require 'util'
_ = require 'underscore'
Queue = require 'queue-async'

Utils = require './utils'
Cursor = require './cursor'

module.exports = class CacheCursor extends Cursor
  toJSON: (callback, count) ->
    # build query
    query = _.extend(_.extend({}, @_find), @_cursor)

    # TODO: invalidate the cache
    @wrapped_sync.cursor(query).toJSON(callback, count)