util = require 'util'
_ = require 'underscore'
Queue = require 'queue-async'

Utils = require './utils'
Cursor = require './cursor'

module.exports = class MemoryCursor extends Cursor
  toJSON: (callback, count) ->
    @_in = {}
    (delete @_find[key]; @_in[key] = value.$in) for key, value of @_find when value?.$in
    keys = _.keys(@_find)

    # only the count
    if count or @_cursor.$count
      json_count = @_count(keys)
      start_index = @_cursor.$offset or 0
      if @_cursor.$one
        json_count = Math.max(0, json_count - start_index)
      else if @_cursor.$limit
        json_count = Math.min(Math.max(0, json_count - start_index), @_cursor.$limit)
      return callback(null, json_count)

    # use find
    if keys.length or _.keys(@_in).length
      json = []
      if @_cursor.$ids
        for id, model_json of @store
          json.push(model_json) if _.contains(@_cursor.$ids, model_json.id) and _.isEqual(_.pick(model_json, keys), @_find)
      else
        for id, model_json of @store
          is_match = true
          for key, value of @_find
            if _.isObject(value) and (value.$lt or value.$lte or value.$gt or value.$gte)
              if value.$lt
                break unless is_match = model_json[key] < value.$lt

              else if value.$lte
                break unless is_match = (model_json[key] <= value.$lte) or _.isEqual(model_json[key], value.$lte)

              if value.$gt
                break unless is_match = model_json[key] > value.$gt

              else if value.$gte
                break unless is_match = (model_json[key] >= value.$gte) or _.isEqual(model_json[key], value.$gte)
              continue

            break unless is_match = _.isEqual(model_json[key], value)

          json.push(model_json) if is_match

        if _.keys(@_in).length
          json = _.filter json, (model_json) =>
            for key, values of @_in
              return true if model_json[key] in values
    else
      # filter by ids
      if @_cursor.$ids
        json = []
        json.push(model_json) for id, model_json of @store when _.contains(@_cursor.$ids, model_json.id)
      else
        json = (model_json for id, model_json of @store)

    if @_cursor.$sort and _.isArray(json)
      $sort_fields = if _.isArray(@_cursor.$sort) then @_cursor.$sort else [@_cursor.$sort]
      json.sort (model, next_model) => return Utils.jsonFieldCompare(model, next_model, $sort_fields)

    if @_cursor.$offset
      number = json.length - @_cursor.$offset
      number = 0 if number < 0
      json = if number then json.slice(@_cursor.$offset, @_cursor.$offset+number) else []

    if @_cursor.$one
      json = if json.length then [json[0]] else []

    else if @_cursor.$limit
      json = json.splice(0, Math.min(json.length, @_cursor.$limit))

    return callback(null, json.length) if count or @_cursor.$count # only the count

    queue = new Queue(1)

    # todo: $select/$values = 'relation.field'
    queue.defer (callback) =>
      if @_cursor.$include
        $include_keys = if _.isArray(@_cursor.$include) then @_cursor.$include else [@_cursor.$include]
        for key in $include_keys
          continue if @model_type.relationIsEmbedded(key)
          needs_lookup = true
          # Load the included models
          load_queue = new Queue(1)
          for model_json in json
            load_queue.defer (callback) =>
              @model_type.relation(key).cursor(model_json, key).toJSON (err, related_json) ->
                model_json[key] = related_json
                callback()
          load_queue.await callback
      callback() unless needs_lookup

    queue.await =>
      # only select specific fields
      if @_cursor.$values
        $fields = if @_cursor.$white_list then _.intersection(@_cursor.$values, @_cursor.$white_list) else @_cursor.$values
      else if @_cursor.$select
        $fields = if @_cursor.$white_list then _.intersection(@_cursor.$select, @_cursor.$white_list) else @_cursor.$select
      else if @_cursor.$white_list
        $fields = @_cursor.$white_list
      json = _.map(json, (data) -> _.pick(data, $fields)) if $fields

      return callback(null, if json.length then json[0] else null) if @_cursor.$one

      # TODO: OPTIMIZE TO REMOVE 'id' and '_rev' if needed
      if @_cursor.$values
        $values = if @_cursor.$white_list then _.intersection(@_cursor.$values, @_cursor.$white_list) else @_cursor.$values
        if @_cursor.$values.length is 1
          key = @_cursor.$values[0]
          json = if $values.length then ((if data.hasOwnProperty(key) then data[key] else null) for data in json) else _.map(json, -> null)
        else
          json = (((data[key] for key in $values when data.hasOwnProperty(key))) for data in json)
      else if @_cursor.$select
        $select = if @_cursor.$white_list then _.intersection(@_cursor.$select, @_cursor.$white_list) else @_cursor.$select
        json = _.map(json, (data) => _.pick(data, $select))
      else if @_cursor.$white_list
        json = _.map(json, (data) => _.pick(data, @_cursor.$white_list))

      if @_cursor.$page or @_cursor.$page is ''
        json =
          offset: @_cursor.$offset
          total_rows: @_count(keys)
          rows: json

      callback(null, json)
    return # terminating

  _count: (keys) =>
    if keys.length
      return _.reduce(@store, ((memo, model_json) => return if _.isEqual(_.pick(model_json, keys), @_find) then memo + 1 else memo), 0)
    else
      return _.size(@store)
