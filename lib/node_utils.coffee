fs = require 'fs'
path = require 'path'
wrench = require 'wrench'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

module.exports = class NodeUtils
  @resetSchemasByDirectory: (directory, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    wrench.readdirRecursive directory, (err, files) ->
      return callback(err) if err
      return callback() unless files

      queue = new Queue(1)
      for file in files
        try
          model_type = require(path.join(directory, file))
          continue unless (model_type and _.isFunction(model_type))
          continue unless (((new model_type()) instanceof Backbone.Model) and model_type.resetSchema)
          do (model_type) -> queue.defer (callback) -> model_type.resetSchema options, callback
        catch e
      queue.await callback