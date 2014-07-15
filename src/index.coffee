###
  backbone-orm.js 0.6.0
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

module.exports =
  sync: require './memory/sync'

  Utils: require './utils'
  JSONUtils: require './json_utils'
  Queue: require './queue'
  DatabaseURL: require './database_url'
  Fabricator: require './fabricator'
  MemoryStore: require './cache/memory_store'

  Cursor: require './cursor'
  Schema: require './schema'
  ConnectionPool: require './connection_pool'
  CacheSingletons: require './cache/singletons'

  _: require 'underscore'
  Backbone: require 'backbone'

  # re-expose modules
  modules:
    url: require 'url'
    querystring: require 'querystring'
    'lru-cache': require 'lru-cache'
    underscore: require 'underscore'
    backbone: require 'backbone'
    moment: require 'moment'
    inflection: require 'inflection'

# re-expose modules
try module.exports.modules.stream = require('stream') catch e
