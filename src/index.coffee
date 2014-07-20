###
<<<<<<< HEAD
  backbone-orm.js 0.5.18
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
=======
  backbone-orm.js 0.6.0
  Copyright (c) 2013-2014 Vidigami
>>>>>>> 40bc5032387d4231b69d247c29e721b4dfccc8d3
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

module.exports = BackboneORM = require './core' # avoid circular dependencies
publish =
  configure: require './lib/configure'
  sync: require './sync'

  Utils: require './lib/utils'
  JSONUtils: require './lib/json_utils'
  DateUtils: require './lib/date_utils'
  Queue: require './lib/queue'
  DatabaseURL: require './lib/database_url'
  Fabricator: require './lib/fabricator'
  MemoryStore: require './cache/memory_store'

  Cursor: require './lib/cursor'
  Schema: require './lib/schema'
  ConnectionPool: require './lib/connection_pool'
  BaseConvention: require './conventions/base'

  _: require 'underscore'
  Backbone: require 'backbone'
publish._.extend(BackboneORM, publish)

# re-expose modules
BackboneORM.modules =
  underscore: require 'underscore'
  backbone: require 'backbone'
  url: require 'url'
  querystring: require 'querystring'
  'lru-cache': require 'lru-cache'
  inflection: require 'inflection'
try BackboneORM.modules.stream = require('stream')
