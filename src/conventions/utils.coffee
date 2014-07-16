module.exports = class Utils
  @conventions = null

  @set: (_conventions) -> Utils.conventions = _conventions
  @get: -> Utils.conventions

Utils.set(require './defaults')
