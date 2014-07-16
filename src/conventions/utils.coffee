_ = require 'underscore'

module.exports = class Utils
  @conventions = _.clone(require './defaults')

  @set: (_conventions) -> Utils.conventions = _conventions
  @get: -> Utils.conventions
