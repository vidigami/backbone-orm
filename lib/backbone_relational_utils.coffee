_ = require 'underscore'
Backbone = require 'backbone-relational'

module.exports = class Store
  @find: (model_type, id) ->
    return Backbone.Relational.store.find(model_type, id) if ((new model_type()) instanceof Backbone.RelationalModel) and id
    return null

  @findOrCreate: (model_type, attributes) ->
    model = new model_type()
    model = existing_model if (model instanceof Backbone.RelationalModel) and attributes.id and (existing_model = Store.find(model_type, attributes.id))
    model.set(attributes)
    return model