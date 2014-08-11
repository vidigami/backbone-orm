###
  backbone-orm.js 0.6.5
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'

# @nodoc
module.exports = class CacheCursor extends (require '../cursor')
  toJSON: (callback) -> @wrapped_sync_fn('cursor', _.extend({}, @_find, @_cursor)).toJSON callback
