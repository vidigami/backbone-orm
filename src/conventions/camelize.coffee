inflection = require 'inflection'
BaseConvention = require './base'

module.exports = class CamelizeConvention extends BaseConvention

  @attribute: (model_name, plural) ->
    inflection[if plural then 'pluralize' else 'singularize'](inflection.camelize(model_name, true))
