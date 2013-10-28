loadDependency = (info) ->
  try dep = require(info.path) catch err then
  return dep if dep
  unless dep = @[info.symbol]
    return if info.optional
    throw new Error("Missing dependency: #{info.path}")
  window.require.register info.path, (exports, require, module) -> module.exports = dep

# ensure the client symbols are resolved
if window?.require.register
  loadDependency({symbol: '_', path: 'lodash', optional: true})
  loadDependency({symbol: '_', path: 'underscore'})
  loadDependency({symbol: 'Backbone', path: 'backbone'})
  loadDependency({symbol: 'moment', path: 'moment'})
  loadDependency({symbol: 'inflection', path: 'inflection'})

module.exports =
  sync: require './memory/sync'

  Utils: require './utils'
  JSONUtils: require './json_utils'
  DatabaseURL: require './database_url'
  Queue: require './queue'

  ConnectionPool: require './connection_pool'
  CacheSingletons: require './cache/singletons'
