###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

URL = require 'url'
Backbone = require 'backbone'
_ = require 'underscore'

BackboneORM = require '../core'
DatabaseURL = require './database_url'
Queue = require './queue'
JSONUtils = require './json_utils'
IterationUtils = require './iteration_utils'
modelExtensions = null

module.exports = class Utils
  @resetSchemas: (model_types, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    # ensure all models all initialized (reverse relationships may be initialized in a dependent model)
    model_type.schema() for model_type in model_types

    failed_schemas = []
    Utils.each model_types, ((model_type, callback) ->
      model_type.resetSchema options, (err) ->
        if err
          failed_schemas.push(model_type.model_name)
          console.log "Error when dropping schema for #{model_type.model_name}. #{err}"
        callback()
    ), (err) ->
      console.log "#{model_types.length - failed_schemas.length} schemas dropped." if options.verbose

      BackboneORM.model_cache.reset()
      return callback(new Error("Failed to migrate schemas: #{failed_schemas.join(', ')}")) if failed_schemas.length
      callback()

  # @nodoc
  @bbCallback: (callback) -> return {success: ((model, resp, options) -> callback(null, model, resp, options)), error: ((model, resp, options) -> callback(resp or new Error('Backbone call failed'), model, resp, options))}

  # @nodoc
  @wrapOptions: (options={}, callback) ->
    options = Utils.bbCallback(options) if _.isFunction(options) # node style callback
    return _.defaults(Utils.bbCallback((err, model, resp, modified_options) -> callback(err, model, resp, options)), options)

  # use signatures as a check in case multiple versions of Backbone have been included

  # @nodoc
  @isModel: (obj) -> return obj and obj.attributes and ((obj instanceof Backbone.Model) or (obj.parse and obj.fetch))

  # @nodoc
  @isCollection: (obj) -> return obj and obj.models and ((obj instanceof Backbone.Collection) or (obj.reset and obj.fetch))

  # @nodoc
  @get: (obj, key, default_value) -> return if not obj._orm or not obj._orm.hasOwnProperty(key) then default_value else obj._orm[key]

  # @nodoc
  @set: (obj, key, value) -> return ((obj._orm or= {}))[key] = value

  # @nodoc
  @orSet: (obj, key, value) -> obj._orm[key] = value unless ((obj._orm or= {})).hasOwnProperty(key); return obj._orm[key]

  # @nodoc
  @unset: (obj, key) -> delete (obj._orm or= {})[key]

  ##############################
  # ModelType
  ##############################

  # @nodoc
  @findOrGenerateModelName: (model_type) ->
    return model_type::model_name if model_type::model_name
    if url = _.result(new model_type, 'url')
      return model_name if model_name = (new DatabaseURL(url)).modelName()
    return model_type.name if model_type.name
    throw "Could not find or generate model name for #{model_type}"

  # @nodoc
  @configureCollectionModelType: (type, sync) ->
    modelURL = ->
      url = _.result((@collection or type.prototype), 'url')
      unless @isNew()
        url_parts = URL.parse(url)
        url_parts.pathname = "#{url_parts.pathname}/encodeURIComponent(@id)"
        url = URL.format(url_parts)
      return url

    model_type = type::model
    if not model_type or (model_type is Backbone.Model)
      # @nodoc
      class ORMModel extends Backbone.Model
        url: modelURL
        schema: type::schema
        sync: sync(ORMModel)
      return type::model = ORMModel
    else if model_type::sync is Backbone.Model::sync # override built-in backbone sync
      model_type::url = modelURL
      model_type::schema = type::schema # TODO: handle the case where the schema is already configured
      model_type::sync = sync(model_type)
    return model_type

  # @nodoc
  @configureModelType: (type) ->
    modelExtensions or= require '../extensions/model' # break dependency cycle
    modelExtensions(type)

  # @nodoc
  @patchRemove: (model_type, model, callback) ->
    return callback() unless schema = model_type.schema()
    queue = new Queue(1)
    for key, relation of schema.relations
      do (relation) -> queue.defer (callback) -> relation.patchRemove(model, callback)
    queue.await callback

  # TODO: remove
  # @nodoc
  @patchRemoveByJSON: (model_type, model_json, callback) -> Utils.patchRemove(model_type, model_json, callback)

  # @nodoc
  @presaveBelongsToRelationships: (model, callback) ->
    return callback() if not model.schema
    queue = new Queue(1)
    schema = model.schema()

    for key, relation of schema.relations
      continue if relation.type isnt 'belongsTo' or relation.isVirtual() or not (value = model.get(key))
      related_models = if value.models then value.models else [value]
      for related_model in related_models
        continue if related_model.id # belongsTo require an id
        do (related_model) => queue.defer (callback) => related_model.save callback

    queue.await callback

  ##############################
  # Data to Model Helpers
  ##############################

  # @nodoc
  @dataId: (data) -> return if _.isObject(data) then data.id else data

  # @nodoc
  @dataIsSameModel: (data1, data2) ->
    return Utils.dataId(data1) is Utils.dataId(data2) if Utils.dataId(data1) or Utils.dataId(data2)
    return _.isEqual(data1, data2)

  # @nodoc
  @dataToModel: (data, model_type) ->
    return null unless data
    return (Utils.dataToModel(item, model_type) for item in data) if _.isArray(data)
    if Utils.isModel(data)
      model = data
    else if Utils.dataId(data) isnt data
      model = new model_type(model_type::parse(data))
    else
      (attributes = {})[model_type::idAttribute] = data
      model = new model_type(attributes)
      model.setLoaded(false)

    return model

  # @nodoc
  @updateModel: (model, data) ->
    return model if not data or (model is data) or data._orm_needs_load
    data = data.toJSON() if Utils.isModel(data)
    if Utils.dataId(data) isnt data
      model.setLoaded(true)
      model.set(data)

      # TODO: handle partial models
      # schema = model.schema()
      # for key of model.attributes
      #   continue unless _.isUndefined(data[key])
      #   if schema and relation = schema.relation(key)
      #     model.unset(key) if relation.type is 'belongsTo' and _.isUndefined(data[relation.virtual_id_accessor]) # unset removed keys
      #   else
      #     model.unset(key)
    return model

  # @nodoc
  @updateOrNew: (data, model_type) ->
    if (cache = model_type.cache) and (id = Utils.dataId(data))
      if Utils.isModel(data) and data.isLoaded()
        model = data
      else if model = cache.get(id)
        Utils.updateModel(model, data)
    unless model
      model = if Utils.isModel(data) then data else Utils.dataToModel(data, model_type)
      cache.set(model.id, model) if model and cache
    return model

  # @nodoc
  @modelJSONSave: (model_json, model_type, callback) ->
    model_type._orm or= {}
    unless model_type._orm.model_type_json
      try url_root = _.result(new model_type, 'url')

      model_type._orm.model_type_json = class JSONModel extends Backbone.Model
        _orm_never_cache: true
        urlRoot: -> url_root

    model_json = _.pick(model_json, model_type::whitelist) if model_type::whitelist
    model_type::sync 'update', new model_type._orm.model_type_json(model_json), Utils.bbCallback callback

  ##############################
  # Iterating
  ##############################

  # @nodoc
  @each: IterationUtils.each

  # @nodoc
  @eachC: (array, callback, iterator) => IterationUtils.each(array, iterator, callback)

  # @nodoc
  @popEach: IterationUtils.popEach

  # @nodoc
  @popEachC: (array, callback, iterator) => IterationUtils.popEach(array, iterator, callback)

  # @nodoc
  @eachDone: IterationUtils.eachDone

  # @nodoc
  @eachDoneC: (array, callback, iterator) => IterationUtils.eachDone(array, iterator, callback)

  ##############################
  # Sorting
  ##############################
  # @nodoc
  @isSorted: (models, fields) ->
    fields = _.uniq(fields)
    for model in models
      return false if last_model and @fieldCompare(last_model, model, fields) is 1
      last_model = model
    return true

  # @nodoc
  @fieldCompare: (model, other_model, fields) ->
    field = fields[0]
    field = field[0] if _.isArray(field) # for mongo

    if field.charAt(0) is '-'
      field = field.substr(1)
      desc = true
    if model.get(field) == other_model.get(field)
      return if fields.length > 1 then @fieldCompare(model, other_model, fields.splice(1)) else 0
    if desc
      return if model.get(field) < other_model.get(field) then 1 else -1
    else
      return if model.get(field) > other_model.get(field) then 1 else -1

  # @nodoc
  @jsonFieldCompare: (model, other_model, fields) ->
    field = fields[0]
    field = field[0] if _.isArray(field) # for mongo

    # reverse
    (field = field.substr(1); desc = true) if field.charAt(0) is '-'

    if model[field] == other_model[field]
      return if fields.length > 1 then @jsonFieldCompare(model, other_model, fields.splice(1)) else 0
    if desc
      return if JSONUtils.stringify(model[field]) < JSONUtils.stringify(other_model[field]) then 1 else -1
    else
      return if JSONUtils.stringify(model[field]) > JSONUtils.stringify(other_model[field]) then 1 else -1
