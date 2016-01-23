###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
Backbone = require 'backbone'

module.exports = BackboneORM = require './core' # avoid circular dependencies
publish =
  configure: require './lib/configure'
  sync: require './sync'

  Utils: require './lib/utils'
  JSONUtils: require './lib/json_utils'
  DateUtils: require './lib/date_utils'
  TestUtils: require './lib/test_utils'
  Queue: require './lib/queue'
  DatabaseURL: require './lib/database_url'
  Fabricator: require './lib/fabricator'
  MemoryStore: require './cache/memory_store'

  Cursor: require './lib/cursor'
  Schema: require './lib/schema'
  ConnectionPool: require './lib/connection_pool'
  BaseConvention: require './conventions/base'

  _: _
  Backbone: Backbone
_.extend(BackboneORM, publish)

# load monkey patches
require './monkey_patches'

# re-expose modules
BackboneORM.modules =
  underscore: _
  backbone: Backbone
  url: require 'url'
  querystring: require 'querystring'
  'lru-cache': require 'lru-cache'
  inflection: require 'inflection'
try BackboneORM.modules.stream = require('stream')
