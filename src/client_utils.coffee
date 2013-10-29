###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###

module.exports = class ClientUtils
  @loadDependency: (item) ->
    return unless window?

    # already registered with local require
    try return if require(item.path) catch err

    # use global require
    try dep = window.require?(item.path) catch err

    # use path on window
    if not dep and item.symbol
      dep = window
      break for key in item.symbol.split('.') when not dep = dep[key]

    # use path on global require (a symbol could be mixed into a module)
    if not dep and item.symbol_path and window.require
      components = item.symbol_path.split('.'); path = components.shift();
      try dep = window.require?(path) catch err
      break for key in components when not dep = dep?[key]

    # not found
    (return if item.optional; throw new Error("Missing dependency: #{item.path}")) unless dep

    # register with local require
    require.register item.path, ((exports, require, module) -> module.exports = dep)
    require.register item.alias, ((exports, require, module) -> module.exports = dep) if item.alias

  @loadDependencies: (info) -> @loadDependency(item) for item in info; return
