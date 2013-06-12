
CLASS_METHODS = [
  'cursor', 'find'
  'count', 'all', 'destroy'
]

class Cache
  @initialize: (model_type, sync) ->
    ###################################
    # Collection Extensions
    ###################################
    model_type.cursor = (query={}) ->
      return new CacheCursor(query, {model_type: model_type})

    model_type.find = (query, callback) ->
      [query, callback] = [{}, query] if arguments.length is 1
      model_type.cursor(query).toModels(callback)

    ###################################
    # Convenience Functions
    ###################################
    model_type.all = (callback) -> model_type.cursor({}).toModels callback

    model_type.count = (query, callback) ->
      [query, callback] = [{}, query] if arguments.length is 1
      model_type.cursor(query).count(callback)

    destroy = (query, callback) ->
      [query, callback] = [{}, query] if arguments.length is 1
      sync.destroy query, (err) ->
        # both clear the cache and destroy
      return callback()

