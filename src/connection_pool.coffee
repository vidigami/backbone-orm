###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###

MemoryStore = require './cache/memory_store'

module.exports = new MemoryStore({destroy: (url, connection) -> connection.destroy()})
