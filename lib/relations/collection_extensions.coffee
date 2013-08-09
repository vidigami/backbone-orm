util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'

Utils = require './utils'

module.exports = (collection_type) ->
  class BackboneCollectionExtensions

  ###################################
  # Backbone ORM - Collection Overrides
  ###################################

  _original_get = collection_type::get
  collection_type::get = (key, callback) ->
    schema = collection_type.schema() if collection_type.schema

    if schema and (relation = schema.relation(key))
      return relation.get(@, key, callback)
    else
      value = _original_get.call(@, key)
      callback(null, value) if callback
      return value
