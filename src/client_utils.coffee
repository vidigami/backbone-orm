isArray = require('../node/util').isArray

module.exports = class ClientUtils
  @loadDependency: (info) ->
    return unless window?.require.register

    info = [info] unless isArray(info)
    for item in info
      try dep = require(item.path) catch err then
      return dep if dep
      unless dep = @[item.symbol]
        return if item.optional
        throw new Error("Missing dependency: #{item.path}")
      window.require.register item.path, (exports, require, module) -> module.exports = dep
