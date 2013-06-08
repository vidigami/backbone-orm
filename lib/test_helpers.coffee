Queue = require 'queue-async'

module.exports = class Helpers
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
      for album in all_models
        do (album) -> queue.defer (callback) -> album.save {name: name}, adapters.bbCallback callback
      queue.await callback

adapters = Helpers.adapters