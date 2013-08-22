util = require 'util'
fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'

resetFiles = (directory, options, callback) ->
  fs.readdir directory, (err, files) ->
    return callback(err) if err
    return callback() unless files

    queue = new Queue(1)

    for file in files
      do (file) -> queue.defer (callback) ->
        pathed_file = path.join(directory, file)
        fs.stat pathed_file, (err, stat) ->
          return callback(err) if err

          return resetFiles(pathed_file, options, callback) if stat.isDirectory() # a directory
          extension = path.extname(pathed_file)
          return callback() unless (extension is '.js' or extension is '.coffee')

          try
            model_type = require(path.join(directory, file))
            return callback() unless (model_type and _.isFunction(model_type) and ((new model_type()) instanceof Backbone.Model) and model_type.resetSchema)
            model_type.resetSchema options, callback

          catch err
            console.log "resetSchemasByDirectory: skipping: #{err}" if options.verbose
            callback()

    queue.await callback

module.exports = class NodeUtils
  @resetSchemasByDirectory: (directory, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    resetFiles directory, options, (err) ->
      console.log "resetSchemasByDirectory: failed to reset schemas: #{err}" if err
      callback(err)
