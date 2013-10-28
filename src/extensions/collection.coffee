###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###

Backbone = require 'backbone'

Utils = require '../utils'

_original__prepareModel = Backbone.Collection::_prepareModel
Backbone.Collection::_prepareModel = (attrs, options) ->
  if not Utils.isModel(attrs) and (id = Utils.dataId(attrs))
    is_new = !!@model.cache.get(id) if @model.cache
    model = Utils.updateOrNew(attrs, @model)
    if is_new and not model._validate(attrs, options)
      this.trigger('invalid', @, attrs, options)
      return false
    return model
  _original__prepareModel.call(@, attrs, options)
