try BackboneORM = require 'backbone-orm' catch err then BackboneORM = require('../../backbone-orm')
Queue = BackboneORM.Queue

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> require('./all_cache')(options, callback)
  queue.defer (callback) -> require('./all_collection')(options, callback)
  queue.defer (callback) -> return callback() if window?; require('./all_conventions')(options, callback) # TODO: something expensive is running here
  queue.defer (callback) -> return callback() if window?; require('./all_compatibility')(options, callback) # TODO: something expensive is running here
  # queue.defer (callback) -> require('./all_flat')(options, callback) # TODO: fix in Node.js
  # queue.defer (callback) -> require('./all_iteration')(options, callback) # TODO: fix in Node.js
  # queue.defer (callback) -> require('./all_migrations')(options, callback) # TODO: exclude from browser build
  queue.defer (callback) -> return callback() if window?; require('./all_relational')(options, callback) # TODO: something expensive is running here
  queue.await callback
