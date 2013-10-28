###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###

# ensure the client symbols are resolved
ClientUtils = require './client_utils'

ClientUtils.loadDependencies([
  {symbol: '_', path: 'lodash', optional: true}, {symbol: '_', path: 'underscore'}
  {symbol: 'Backbone', path: 'backbone'}
  {symbol: 'moment', path: 'moment'}
  {symbol: 'inflection', path: 'inflection'}
])

module.exports =
  sync: require './memory/sync'

  Utils: require './utils'
  JSONUtils: require './json_utils'
  DatabaseURL: require './database_url'
  Queue: require './queue'

  ConnectionPool: require './connection_pool'
  CacheSingletons: require './cache/singletons'
