util = require 'util'
URL = require 'url'
_ = require 'underscore'
Queue = require 'queue-async'
inflection = require 'inflection'

module.exports = class RelationManager

  constructor: (@model_type, @relations, options={}) ->

  get: (model, relation, options) ->
    if relation = @relations[relation]
      related_model_type = relation.model
      relation_type = relation.type
      foreign_key = relation.options.foreignKey
      query = {}

      if relation_type is 'hasMany'
        query[foreign_key] = model.attributes.id
        related_model_type.cursor(query).toModels (err, json) ->
          return options.error(err) if err
          return options.error(new Error "Model not found. Id #{query[foreign_key]}") if not json
          options.success?(json)

      if relation_type is 'hasOne'
        query[foreign_key] = model.attributes.id
        related_model_type.cursor(query).toModels (err, json) ->
          return options.error(err) if err
          return options.error(new Error "Model not found. Id #{query[foreign_key]}") if not json
          options.success?(json)

    else
      return model.attributes[relation]

module.exports = (model_type, options) ->
  manager = new RelationManager(model_type, options)
  return (relation, options) -> manager.get(@, relation, options)
