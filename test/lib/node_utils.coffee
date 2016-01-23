###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Backbone = require 'backbone'

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../backbone-orm')
{Queue, Utils} = BackboneORM

# @private
module.exports = class NodeUtils

  @findModels = (directory, options, callback) ->
    model_types = []

    findModelsInDirectory = (directory, options, callback) ->
      fs.readdir directory, (err, files) ->
        return callback(err) if err
        return callback(null, model_types) unless files

        Utils.each files, ((file, callback) ->
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
              console.log "findModels: skipping: #{err}" if options.verbose
              callback()
        ), (err) -> if err then callback(err) else callback(null, model_types)

        queue = new Queue(1)

    findModelsInDirectory(directory, options, callback)

  @resetSchemasByDirectory: (directory, options, callback) =>
    [options, callback] = [{}, options] if arguments.length is 2

    @findModels directory, options, (err, model_types) ->
      return callback(err) if err

      Utils.each model_types, ((model_type, callback) -> model_type.resetSchema options, callback), (err) ->
        !err or console.log "resetSchemasByDirectory: failed to reset schemas: #{err}"
        callback(err)
