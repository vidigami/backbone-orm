inflection = require 'inflection'
BaseConvention = require './base'

module.exports = class UnderscoreConvention extends BaseConvention

  @attribute: (model_name, plural) ->
    inflection[if plural then 'pluralize' else 'singularize'](inflection.underscore(model_name))
