util = require 'util'
URL = require 'url'
_ = require 'underscore'
Queue = require 'queue-async'
inflection = require 'inflection'

module.exports = class RelationManager

  constructor: (@model_type, @relations, options={}) ->

  getMany: (model, relation, options) ->
    related_model_type = relation.model
    query = {}
    query[relation.foreign_key] = model.attributes.id
    related_model_type.cursor(query).toModels (err, json) ->
      return options.error(err) if err
      return options.error(new Error "Model not found. Id #{query[foreign_key]}") if not json
      options.success?(json)

  getOne: (model, relation, options) ->
    related_model_type = relation.model
    query = {$one: true}
    if relation.reverse
      query[relation.foreign_key] = model.attributes.id
    else
      query.id = model.get(relation.foreign_key)
    related_model_type.cursor(query).toModels (err, json) ->
      return options.error(err) if err
      return options.error(new Error "Model not found. Id #{query[foreign_key]}") if not json
      options.success?(json)

  get: (model, attr, options) ->
    if relation = @relations[attr]
      relation_type = relation.type
      return @getMany(model, relation, options) if relation_type is 'hasMany'
      return @getOne(model, relation, options) if relation_type is 'hasOne'
    else
      return model.attributes[attr]

module.exports = (model_type, options) ->
  manager = new RelationManager(model_type, options)
  return (relation, options) -> return manager.get(@, relation, options)
