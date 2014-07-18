inflection = require 'inflection'
BaseConvention = require './base'

module.exports = class ClassifyConvention extends BaseConvention

  @attribute: (model_name, plural) ->
    inflection[if plural then 'pluralize' else 'singularize'](inflection.camelize(model_name, false))
