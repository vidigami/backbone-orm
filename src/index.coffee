###
  backbone-orm.js 0.5.16
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

# ensure the symbols are resolved
require.shim([
  {symbol: '_', path: 'lodash', alias: 'underscore', optional: true}, {symbol: '_', path: 'underscore'}
  {symbol: 'Backbone', path: 'backbone'}
  {symbol: 'moment', path: 'moment'}
  # {symbol: 'inflection', path: 'inflection'} # burned in
  {symbol: 'stream', path: 'stream', optional: true} # stream is large so it is optional on the client
  {symbol: 'fs', path: 'fs', optional: window?}
  {symbol: 'path', path: 'path', optional: window?}
  {symbol: 'crypto', path: 'crypto', optional: window?}
]) if require.shim

module.exports =
  sync: require './memory/sync'

  Utils: require './utils'
  NodeUtils: require './node/utils'
  JSONUtils: require './json_utils'
  Queue: require './queue'
  DatabaseURL: require './database_url'

  # re-expose modules
  modules:
    url: require 'url'
    querystring: require 'querystring'
    'lru-cache': require 'lru-cache'
    underscore: require 'underscore'
    backbone: require 'backbone'
    moment: require 'moment'
    inflection: require 'inflection'

  Cursor: require './cursor'
  Schema: require './schema'
  ConnectionPool: require './connection_pool'
  CacheSingletons: require './cache/singletons'

# re-expose modules
try module.exports.modules.stream = require('stream') catch e
