###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###

module.exports = class ClientUtils
  @loadDependency: (item) ->
    return unless window?
    try return if require(item.path) catch err # already required

    try dep = window.require?(item.path) catch err
    unless dep
      dep = window
      break for key in item.symbol.split('.') when not dep = dep[key]
    (return if item.optional; throw new Error("Missing dependency: #{item.path}")) unless dep
    require.register item.path, ((exports, require, module) -> module.exports = dep)
    require.register item.alias, ((exports, require, module) -> module.exports = dep) if item.alias

  @loadDependencies: (info) -> @loadDependency(item) for item in info; return
