inflection = require 'inflection'

module.exports = class BaseConvention
  @modelName: (table_name, plural) ->
    inflection[if plural then 'pluralize' else 'singularize'](inflection.classify(table_name))

  @tableName: (model_name) ->
    inflection.pluralize(inflection.underscore(model_name))

  @foreignKey: (model_name, plural) ->
    if plural
      inflection.singularize(inflection.underscore(model_name)) + '_ids'
    else
      inflection.underscore(model_name) + '_id'

  @attribute: (model_name, plural) ->
    inflection[if plural then 'pluralize' else 'singularize'](inflection.underscore(model_name))
