###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###

isArray = require('../node/util').isArray

module.exports = class ClientUtils
  @loadDependencies: (info) ->
    return unless window?.require.register

    info = [info] unless isArray(info)
    for item in info
      do (item) ->
        try return if dep = require(item.path) catch err then
        unless dep = @[item.symbol]
          return if item.optional
          throw new Error("Missing dependency: #{item.path}")
        window.require.register item.path, (exports, require, module) -> module.exports = dep
    return
