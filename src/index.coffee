# ensure the client symbols are resolved
require('./client_utils').loadDependency([
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
