###
  backbone-orm.js 0.6.0
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

module.exports = BackboneORM = require './core' # avoid circular dependencies
publish =
  configure: require './configure'
  sync: require './memory/sync'

  Utils: require './utils'
  JSONUtils: require './json_utils'
  DateUtils: require './date_utils'
  Queue: require './queue'
  DatabaseURL: require './database_url'
  Fabricator: require './fabricator'
  MemoryStore: require './cache/memory_store'

  Cursor: require './cursor'
  Schema: require './schema'
  ConnectionPool: require './connection_pool'
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
