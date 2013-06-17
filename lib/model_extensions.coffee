module.exports = (model_type, sync) ->

  ###################################
  # Backbone ORM - Class Extensions
  ###################################
  model_type.cursor = (query={}) ->
    sync('cursor', query)

  model_type.destroy = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    sync('destroy', query, callback)

  ###################################
  # Backbone ORM - Convenience Functions
  ###################################
  model_type.count = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    sync('cursor', query).count(callback)

  model_type.all = (callback) ->
    sync('cursor', {}).toModels(callback)

  model_type.find = (query, callback) ->
    [query, callback] = [{}, query] if arguments.length is 1
    sync('cursor', query).toModels(callback)
