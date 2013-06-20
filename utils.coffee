util = require 'util'
URL = require 'url'
Backbone = require 'backbone'
_ = require 'underscore'
inflection = require 'inflection'
Queue = require 'queue-async'

S4 = -> (((1+Math.random())*0x10000)|0).toString(16).substring(1)

module.exports = class Utils
  @adapters:
    bbCallback: (callback) -> return {success: ((model) -> callback(null, model)), error: ((model, err) -> callback(err or new Error("Backbone call failed")))}

  # parse an object whose values are still JSON stringified
  @parse: (query) ->
    return JSON.parse(query) if _.isString(query)
    result = {}
    for key, value of query
      try result[key] = JSON.parse(value) catch err then result[key] = value
    return result

  @guid = -> return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())

  @urlToModelName: (url) ->
    url_parts = URL.parse(url)
    database_parts = url_parts.pathname.split('/')
    table = database_parts[database_parts.length-1]
    return inflection.classify(inflection.singularize(table))

  @urlToDatabaseEndpoint: (url) ->
    url_parts = URL.parse(url)
    database_parts = url_parts.pathname.split('/')
    database_parts.pop()
    url_parts.pathname = database_parts.join('/')
    URL.format(url_parts)

  ##############################
  # Relational
  ##############################
  @createRelated: (model_type, item) ->
    return item if (item instanceof Backbone.Model) or (item instanceof Backbone.Collection)
    if model_type._cache
      return model_type._cache.findCachedOrCreate(item, model_type)
    else
      return new model_type(model_type::parse(item)) if _.isObject(item)
      related_model = new model_type({id: item})
      related_model._orm_needs_load = true
      return related_model

  @reverseRelation: (model_type, owning_model_name) ->
    return null unless model_type.relation
    reverse_key = inflection.underscore(owning_model_name)
    return relation if relation = model_type.relation(reverse_key = inflection.underscore(owning_model_name)) # singular
    return model_type.relation(inflection.pluralize(reverse_key)) # plural

  @dataId: (item) ->
    if item instanceof Backbone.Model
      return item.get('id')
    else if _.isObject(item)
      return item.id
    return item

  @createJoinTableModel: (relation1, relation2) ->
    model_name1 = inflection.pluralize(inflection.underscore(relation1.model_type.model_name))
    model_name2 = inflection.pluralize(inflection.underscore(relation2.model_type.model_name))
    table_name = if model_name1.localeCompare(model_name2) < 0 then "#{model_name1}_#{model_name2}" else "#{model_name2}_#{model_name1}"

    schema = {}
    schema[relation1.foreign_key] = ['Integer', indexed: true]
    schema[relation2.foreign_key] = ['Integer', indexed: true]

    class JoinTable extends Backbone.Model
      url: "#{Utils.urlToDatabaseEndpoint(relation1.model_type::url)}/#{table_name}"
      @schema = schema
      sync: relation1.model_type.createSync(JoinTable)

    return JoinTable

  ##############################
  # Testing
  ##############################
  @setAllNames: (model_type, name, callback) ->
    model_type.all (err, all_models) ->
      return callback(err) if err
      queue = new Queue()
      for model in all_models
        do (model) -> queue.defer (callback) -> model.save {name: name}, adapters.bbCallback callback
      queue.await callback

  ##############################
  # Sorting
  ##############################
  @isSorted: (models, fields) ->
    fields = _.uniq(fields)
    for model in models
      return false if last_model and @fieldCompare(last_model, model, fields) is 1
      last_model = model
    return true

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

  @jsonFieldCompare: (model, other_model, fields) ->
    field = fields[0]
    field = field[0] if _.isArray(field) # for mongo

    if field.charAt(0) is '-'
      field = field.substr(1)
      desc = true
    if model[field] == other_model[field]
      return if fields.length > 1 then @jsonFieldCompare(model, other_model, fields.splice(1)) else 0
    if desc
      return if JSON.stringify(model[field]) < JSON.stringify(other_model[field]) then 1 else -1
    else
      return if JSON.stringify(model[field]) > JSON.stringify(other_model[field]) then 1 else -1

adapters = Utils.adapters
