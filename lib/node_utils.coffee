util = require 'util'
fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

module.exports = class NodeUtils

  @findModels = (directory, options, callback) ->

    model_types = []
    findModelsInDirectory = (directory, options, callback) ->
      fs.readdir directory, (err, files) ->

        return callback(err) if err
        return callback(null, model_types) unless files

        queue = new Queue(1)

        for file in files
          do (file) -> queue.defer (callback) ->
            pathed_file = path.join(directory, file)
            fs.stat pathed_file, (err, stat) ->
              return callback(err) if err

              return findModelsInDirectory(pathed_file, options, callback) if stat.isDirectory() # a directory
              extension = path.extname(pathed_file)
              return callback() unless (extension is '.js' or extension is '.coffee')

              try
                model_path = path.join(directory, file)
                model_type = require(model_path)
                return callback() unless (model_type and _.isFunction(model_type) and Utils.isModel(new model_type()) and model_type.resetSchema)
                model_type.path = model_path if options.append_path
                model_types.push(model_type)
                callback()

              catch err
                console.log "resetSchemasByDirectory: skipping: #{err}" if options.verbose
                callback()

        queue.await (err) ->
          callback(err) if err
          callback(null, model_types)

    findModelsInDirectory(directory, options, callback)

  @resetSchemasByDirectory: (directory, options, callback) =>
    [options, callback] = [{}, options] if arguments.length is 2

    @findModels directory, options, (err, model_types) ->

      queue = new Queue(1)

      for model_type in model_types
        do (model_type) -> queue.defer (callback) ->
          model_type.resetSchema options, callback

      queue.await (err) ->
        console.log "resetSchemasByDirectory: failed to reset schemas: #{err}" if err
        callback(err)
