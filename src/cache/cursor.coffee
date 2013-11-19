###
  backbone-orm.js 0.5.2
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
###

_ = require 'underscore'

# @private
module.exports = class CacheCursor extends require('../cursor')
  toJSON: (callback) -> @wrapped_sync_fn('cursor', _.extend({}, @_find, @_cursor)).toJSON callback
