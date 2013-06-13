util = require 'util'
URL = require 'url'
_ = require 'underscore'
Queue = require 'queue-async'
inflection = require 'inflection'

RelationParser = require './parsers/relation'

module.exports = class RelationManager

  constructor: (@model_type, raw_relations) ->
    @relations = RelationParser.parse(@model_type, raw_relations)

    # TODO: monkey patch
    # override model methods
    _this = @

    @model_type::get = (key) ->
      if relation = _this.relations[key]
        relation_type = relation.type
        return _this.getMany(@, relation, options) if relation_type is 'hasMany'
        return _this.getOne(@, relation, options) if relation_type is 'hasOne'
      else
        return @attributes[key]

    @model_type::toJSON = ->
      json = _.clone(@attributes)
      json[key] = value.toJSON() for key, value of json when value.toJSON
      return json

    @model_type._relationship_manager = @

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

module.exports = (model_type, raw_relations) ->
  relation_manager = new RelationManager(model_type, raw_relations)
