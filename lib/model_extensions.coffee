_ = @_ or require 'underscore'

module.exports = (model_type, sync) ->

  ###################################
  # Backbone ORM - Class Extensions
  ###################################
  model_type.cursor = (query={}) -> sync('cursor', query)

  model_type.destroy = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    sync('destroy', query, callback)

  model_type.schema = -> sync('schema')
  model_type.relation = (key) -> sync('relation', key)

  ###################################
  # Backbone ORM - Convenience Functions
  ###################################
  model_type.count = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    sync('cursor', query).count(callback)

  model_type.all = (callback) -> sync('cursor', {}).toModels(callback)

  model_type.find = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    sync('cursor', query).toModels(callback)

  ###################################
  # Backbone ORM - Model Overrides
  ###################################
  _original_set = model_type::set
  model_type::set = (key, value, options) ->
    return _original_set.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

    if _.isString(key)
      (attributes = {})[key] = value;
    else
      attributes = key; options = value

    for key, value of attributes
      if relation = schema.relation(key)
        relation.set(@, key, value, options, _original_set)
      else
        _original_set.call(@, key, value, options)
    return @

  _original_get = model_type::get
  model_type::get = (key, callback) ->
    return _original_get.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

    if relation = schema.relation(key)
      return relation.get(@, key, callback)
    else
      value = _original_get.call(@, key)
      callback(null, value) if callback
      return value

  _original_toJSON = model_type::toJSON
  model_type::toJSON = ->
    return _original_toJSON.apply(@, arguments) unless model_type.schema and (schema = model_type.schema())

    return @get('id') if @_locked > 0
    @_locked or= 0
    @_locked++

    toJSON = (item) -> if (item and item.get and item.toJSON) then item.toJSON() else item

    json = _.clone(@attributes)
    for key, value of json
      continue unless value
      if value.models
        json[key] = _.map(value.models, toJSON)
      else if _.isArray(value)
        json[key] = _.map(value, toJSON)
      else if (value.get and value.toJSON) # model signature
        json[key] = toJSON(value)

    @_locked--
    return json