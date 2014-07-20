###
<<<<<<< HEAD:src/connection_pool.coffee
  backbone-orm.js 0.5.18
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
=======
  backbone-orm.js 0.6.0
  Copyright (c) 2013-2014 Vidigami
>>>>>>> 40bc5032387d4231b69d247c29e721b4dfccc8d3:src/lib/connection_pool.coffee
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

MemoryStore = require '../cache/memory_store'

module.exports = new MemoryStore({destroy: (url, connection) -> connection.destroy()})
