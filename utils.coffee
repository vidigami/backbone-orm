_ = require 'underscore'
Queue = require 'queue-async'

module.exports = class Utils
  @adapters:
    bbCallback: (callback) -> return {success: ((model) -> callback(null, model)), error: (-> callback(new Error("failed")))}

  @getAt: (model_type, index, callback) ->
    model_type.cursor().offset(index).limit(1).toModels (err, models) ->
      return callback(err) if err
      return callback(null, if (models.length is 1) then models[0] else null)

  @setAllNames: (model_type, name, callback) ->
    model_type.all (err, all_models) ->
      return callback(err) if err
      queue = new Queue()
      for model in all_models
        do (model) -> queue.defer (callback) -> model.save {name: name}, adapters.bbCallback callback
      queue.await callback

  @isSorted: (models, fields) ->
    fields = _.uniq(fields)
    for model in models
      return false if last_model and @fieldCompare(last_model, model, fields) is 1
      last_model = model
    return true

  @fieldCompare: (model, other_model, fields) ->
    field = fields[0]
    field = field[0] if Array.isArray(field)
    if field.indexOf('-') is 0
      field = field.substr(1)
      dir = 'desc'
    if model.get(field) == other_model.get(field)
      return if fields.length > 0 then @fieldCompare(model, other_model, fields.splice(1)) else 0
    if dir is 'desc'
      return if model.get(field) < other_model.get(field) then 1 else -1
    else
      return if model.get(field) > other_model.get(field) then 1 else -1

  @jsonFieldCompare: (model, other_model, fields) ->
    field = fields[0]
    field = field[0] if Array.isArray(field) # for mongo
    if field.indexOf('-') is 0
      field = field.substr(1)
      dir = 'desc'
    if model[field] == other_model[field]
      return if fields.length > 0 then @jsonFieldCompare(model, other_model, fields.splice(1)) else 0
    if dir is 'desc'
      return if JSON.stringify(model[field]) < JSON.stringify(other_model[field]) then 1 else -1
    else
      return if JSON.stringify(model[field]) > JSON.stringify(other_model[field]) then 1 else -1

adapters = Utils.adapters