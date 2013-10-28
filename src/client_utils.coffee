###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###

isArray = require('../node/util').isArray

module.exports = class ClientUtils
  @loadDependencies: (info) ->
    return unless window?

    info = [info] unless isArray(info)
    for item in info
      do (item) ->
        try return if require(item.path) catch err # already required
        try dep = window.require?(item.path) catch err
        dep or= window[item.symbol]
        unless dep
          return if item.optional
          throw new Error("Missing dependency: #{item.path}")
        require.register item.path, ((exports, require, module) -> module.exports = dep)
        require.register item.alias, ((exports, require, module) -> module.exports = dep) if item.alias
    return
