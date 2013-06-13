util = require 'util'
URL = require 'url'
_ = require 'underscore'
Queue = require 'queue-async'
inflection = require 'inflection'

SchemaParser = require './parsers/schema'
RelationParser = require './parsers/relation'

module.exports = class RelationManager

  constructor: (@model_type, raw_relations) ->
    @relations = RelationParser.parse(@model_type, raw_relations)

    # override model methods
    _rel_manager = @model_type._rel_manager = @

    # @model_type::set = (attributes) ->
    _get = @model_type::get
    @model_type::get = (key, callback) ->
      if arguments.length > 1
        if relation = _rel_manager.relations[key]
          if relation.type is 'hasMany' then _rel_manager.getMany(@, relation, callback) else _rel_manager.getOne(@, relation, callback)
        else
          callback(null, @attributes[key])
      return _get.apply(@, arguments)

    _toJSON = @model_type::toJSON
    @model_type::toJSON = ->
      json = _toJSON.apply(@, arguments)
      json[key] = value.toJSON() for key, value of json when value.toJSON
      return json
    return

  getMany: (model, relation, callback) ->
    related_model_type = relation.model
    query = {}
    query[relation.foreign_key] = model.attributes.id
    related_model_type.cursor(query).toModels (err, models) ->
      return callback(err) if err
      return callback(new Error "Model not found. Id #{relation.foreign_key}") if not models.length
      callback(null, models)

  getOne: (model, relation, callback) ->
    related_model_type = relation.model
    query = {$one: true}

    console.log "relation.foreign_key: #{relation.foreign_key}"

    if relation.reverse
      query[relation.foreign_key] = model.attributes.id
    else
      query.id = model.get(relation.foreign_key)
    related_model_type.cursor(query).toModels (err, model) ->
      return callback(err) if err
      return callback(new Error "Model not found. Id #{relation.foreign_key}") if not model
      callback(null, model)

module.exports = (model_type, raw_relations) -> new RelationManager(model_type, raw_relations)
