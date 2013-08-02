util = require 'util'
_ = require 'underscore'
Queue = require 'queue-async'
moment = require 'moment'

Utils = require './utils'
Cursor = require './cursor'

IS_MATCH_FNS =
  $ne: (mv, tv) -> return not _.isEqual(mv, tv)

  $lt: (mv, tv) ->
    throw Error 'Cannot compare to null' if _.isNull(tv)
    return (if _.isDate(tv) then moment(mv).isBefore(tv) else mv < tv)

  $lte: (mv, tv) ->
    throw Error 'Cannot compare to null' if _.isNull(tv)
    if _.isDate(tv)
      mvm = moment(mv)
      return mvm.isBefore(tv) or mvm.isSame(tv)
    else
      return (mv < tv) or _.isEqual(mv, tv)

  $gt: (mv, tv) ->
    throw Error 'Cannot compare to null' if _.isNull(tv)
    return (if _.isDate(tv) then moment(mv).isAfter(tv) else mv > tv)

  $gte: (mv, tv) ->
    throw Error 'Cannot compare to null' if _.isNull(tv)
    if _.isDate(tv)
      mvm = moment(mv)
      return mvm.isAfter(tv) or mvm.isSame(tv)
    else
      return (mv > tv) or _.isEqual(mv, tv)
IS_MATCH_OPERATORS = _.keys(IS_MATCH_FNS)

# @private
module.exports = class MemoryCursor extends Cursor
  toJSON: (callback, options) ->
    count = (@_cursor.$count or (options and options.$count))
    exists = @_cursor.$exists or (options and options.$exists)

    json = null
    queue = new Queue(1)

    @_in = {}
    (delete @_find[key]; @_in[key] = value.$in) for key, value of @_find when value?.$in
    keys = _.keys(@_find)

    # only the count
    if count
      json_count = @_count(keys)
      start_index = @_cursor.$offset or 0
      if @_cursor.$one
        json_count = Math.max(0, json_count - start_index)
      else if @_cursor.$limit
        json_count = Math.min(Math.max(0, json_count - start_index), @_cursor.$limit)
      return callback(null, json_count)

    queue.defer (callback) =>
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
              was_handled = false
              model_value = model_json[key]

              # an object might specify $lt, $lte, $gt, $gte, $ne
              if _.isObject(value)
                for operator in IS_MATCH_OPERATORS when value.hasOwnProperty(operator)
                  # console.log "Testing operator: #{operator}, model_value: #{util.inspect(model_value)}, test_value: #{util.inspect(value[operator])} result: #{IS_MATCH_FNS[operator](model_value, value[operator])}"
                  was_handled = true
                  break if not is_match = IS_MATCH_FNS[operator](model_value, value[operator])

              continue if was_handled and is_match
              break unless is_match = _.isEqual(model_value, value) unless was_handled

            json.push(model_json) if is_match

          if _.keys(@_in).length
            json = _.filter json, (model_json) => return true for key, values of @_in when model_json[key] in values

        callback()

      else
        # filter by ids
        if @_cursor.$ids
          json = []
          json.push(model_json) for id, model_json of @store when _.contains(@_cursor.$ids, model_json.id)
        else
          json = (model_json for id, model_json of @store)
        callback()

    if not (count or exists)
      queue.defer (callback) =>
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
        callback()

      # todo: $select/$values = 'relation.field'
      if @_cursor.$include
        queue.defer (callback) =>
          load_queue = new Queue(1)

          $include_keys = if _.isArray(@_cursor.$include) then @_cursor.$include else [@_cursor.$include]
          for key in $include_keys
            continue if @model_type.relationIsEmbedded(key)

            # Load the included models
            for model_json in json
              do (key, model_json) => load_queue.defer (callback) =>
                @model_type.relation(key).cursor(model_json, key).toJSON (err, related_json) ->
                  model_json[key] = related_json
                  callback()

          load_queue.await callback

    queue.await =>
      # TODO: OPTIMIZATION: pull this forward before processing data
      return callback(null, (if _.isArray(json) then !!json.length else json)) if exists
      return callback(null, json.length) if count # only the count

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

      if @_cursor.$page or (@_cursor.$page is '')
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
