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
    ins = {}
    (delete @_find[key]; ins[key] = value.$in) for key, value of @_find when value?.$in
    keys = _.keys(@_find)
    ins_size = _.size(ins)

    json = []
    queue = new Queue(1)

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
      if keys.length or ins_size
        if @_cursor.$ids
          for id, model_json of @store
            json.push(model_json) if _.contains(@_cursor.$ids, model_json.id) and _.isEqual(_.pick(model_json, keys), @_find)
          callback()

        else
          find_queue = new Queue()

          for id, model_json of @store
            do (model_json) => find_queue.defer (callback) =>
              find_keys = _.keys(@_find)
              next = (err, is_match) =>
                # done conditions
                return callback(err) if err
                return callback() unless is_match
                if not find_keys.length or (exists and (keys.length isnt find_keys.length)) # exists only needs one result
                  json.push(model_json)
                  return callback()

                # check next key
                @_valueIsMatch find_keys.pop(), model_json, next

              next(null, true) # start checking

          find_queue.await (err) =>
            return callback(err) if err
            if ins_size
              json = _.filter json, (model_json) => return true for key, values of ins when model_json[key] in values
            callback()

      else
        # filter by ids
        if @_cursor.$ids
          json.push(model_json) for id, model_json of @store when _.contains(@_cursor.$ids, model_json.id)
        else
          json = (model_json for id, model_json of @store)
        callback()

    if not (count or exists)
      queue.defer (callback) =>
        if @_cursor.$sort
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
                return callback(new Error "Missing included relation '#{key}'") unless relation = @model_type.relation(key)

                relation.cursor(model_json, key).toJSON (err, related_json) ->
                  # console.log "\nmodel_json: #{util.inspect(model_json)}\nrelated_json: #{util.inspect(related_json)}"
                  model_json[key] = related_json
                  callback()

          load_queue.await callback

    queue.await =>
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

  _count: (keys) ->
    if keys.length
      return _.reduce(@store, ((memo, model_json) => return if _.isEqual(_.pick(model_json, keys), @_find) then memo + 1 else memo), 0)
    else
      return _.size(@store)

  _valueIsMatch: (key_path, model_json, callback) ->
    key_components = key_path.split('.')
    model_type = @model_type

    next = (err, models_json) =>
      return callback(err) if err
      key = key_components.shift()

      # done conditions
      unless key_components.length
        was_handled = false
        find_value = @_find[key_path]

        models_json = [models_json] unless _.isArray(models_json)
        for model_json in models_json
          model_value = model_json[key]
          # console.log "\nChecking value (#{key_path}): #{key}, find_value: #{util.inspect(find_value)}, model_value: #{util.inspect(model_value)}\nmodel_json: #{util.inspect(model_json)}\nis equal: #{_.isEqual(model_value, find_value)}"

          # an object might specify $lt, $lte, $gt, $gte, $ne
          if _.isObject(find_value)
            for operator in IS_MATCH_OPERATORS when find_value.hasOwnProperty(operator)
              # console.log "Testing operator: #{operator}, model_value: #{util.inspect(model_value)}, test_value: #{util.inspect(find_value[operator])} result: #{IS_MATCH_FNS[operator](model_value, find_value[operator])}"
              was_handled = true
              break if not is_match = IS_MATCH_FNS[operator](model_value, find_value[operator])

          if was_handled
            return callback(null, is_match) if is_match
          else if is_match = _.isEqual(model_value, find_value)
            return callback(null, is_match)

        # checked all models and none were a match
        return callback(null, false)

      # console.log "\nNext model (#{key_path}): #{key} model_json: #{util.inspect(model_json)}"

      # fetch relation
      return relation.cursor(model_json, key).toJSON(next) if (relation = model_type.relation(key)) and not relation.embed
      next(null, model_json[key])

    next(null, model_json) # start checking
