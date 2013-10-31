###
  backbone-orm.js 0.5.0
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
###

# ensure the client symbols are resolved
if window? and require.shim
  require.shim([
    {symbol: '_', path: 'lodash', alias: 'underscore', optional: true}, {symbol: '_', path: 'underscore'}
    {symbol: 'Backbone', path: 'backbone'}
    {symbol: 'moment', path: 'moment'}
    {symbol: 'inflection', path: 'inflection'}
    {symbol: 'stream', path: 'stream', optional: true} # stream is large so it is optional on the client
  ])

module.exports =
  sync: require './memory/sync'

  Utils: require './utils'
  JSONUtils: require './json_utils'
  Queue: require './queue'
  DatabaseURL: require './database_url'

  # re-expose node libraries
  Url: require 'url'
  QueryString: require 'querystring'
  LRUCache: require 'lru-cache'

  Cursor: require './cursor'
  Schema: require './schema'
  ConnectionPool: require './connection_pool'
  CacheSingletons: require './cache/singletons'
