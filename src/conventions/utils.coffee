_ = require 'underscore'

module.exports = class ConventionUtils
  @conventions = _.clone(require './defaults')

  @set: (_conventions) -> ConventionUtils.conventions = _conventions
  @get: -> ConventionUtils.conventions
