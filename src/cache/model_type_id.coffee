###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###
_ = require 'underscore'
crypto = require('crypto');

module.exports = class ModelTypeID

  constructor: ->
    @ids = {}

  reset: =>
    @ids = {}

  modelID: (model_type) =>
    name_url = "#{_.result(model_type.prototype, 'url')}_#{model_type.model_name}"
    return crypto.createHash('md5').update(name_url).digest('hex')

  generate: (model_type) =>
    id = @modelID(model_type)
    if @ids[id] and @ids[id] isnt model_type
      throw new Error("Duplicate model name / url combination: #{model_type.model_name}, #{_.result(model_type.prototype, 'url')}. Set a unique model_name property on one of the conflicting models.")
    @ids[id] = model_type
    return id
