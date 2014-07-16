inflection = require 'inflection'

module.exports =
  modelName: (table_name, plural) -> inflection[if plural then 'pluralize' else 'singularize'](inflection.classify(table_name))
  tableName: (model_name) -> inflection.pluralize(inflection.underscore(model_name))
  attribute: (model_name, plural) -> inflection[if plural then 'pluralize' else 'singularize'](inflection.underscore(model_name))
  foreignKey: (model_name, plural) ->
    if plural
      inflection.foreign_key(inflection.singularize(model_name)) + 's'
    else
      result = inflection.foreign_key(model_name)
