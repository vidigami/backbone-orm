_ = require 'underscore'

# @private
module.exports = class CacheCursor extends require('./cursor')
  toJSON: (callback) -> @wrapped_sync_fn('cursor', _.extend({}, @_find, @_cursor)).toJSON callback
