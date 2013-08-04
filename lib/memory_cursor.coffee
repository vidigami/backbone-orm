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

    @buildFindQuery (err, find_query) =>
      keys = _.keys(find_query)
      json = []
      queue = new Queue(1)

      # only the count
      if count
        json_count = @_count(find_query, keys)
        start_index = @_cursor.$offset or 0
        if @_cursor.$one
          json_count = Math.max(0, json_count - start_index)
        else if @_cursor.$limit
          json_count = Math.min(Math.max(0, json_count - start_index), @_cursor.$limit)
        return callback(null, json_count)

      queue.defer (callback) =>
        ins = {}
        (delete find_query[key]; ins[key] = value.$in) for key, value of find_query when value?.$in
        ins_size = _.size(ins)

        # use find
        if keys.length or ins_size
          if @_cursor.$ids
            for id, model_json of @store
              json.push(model_json) if _.contains(@_cursor.$ids, model_json.id) and _.isEqual(_.pick(model_json, keys), find_query)
            callback()

          else
            find_queue = new Queue()
            # console.log "\nmodel: #{@model_type.model_name} find_query: #{util.inspect(find_query)} @store: #{util.inspect(@store)}"

            for id, model_json of @store
              do (model_json) => find_queue.defer (callback) =>
                find_keys = _.keys(find_query)
                next = (err, is_match) =>
                  # done conditions
                  return callback(err) if err
                  return callback() unless is_match
                  if not find_keys.length or (exists and (keys.length isnt find_keys.length)) # exists only needs one result
                    json.push(model_json)
                    return callback()

                  # check next key
                  @_valueIsMatch(find_query, find_keys.pop(), model_json, next)

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

      if not exists
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

        queue.defer (callback) => @fetchIncludes(json, callback)

      queue.await =>
        return callback(null, (if _.isArray(json) then !!json.length else json)) if exists
        return callback(null, if json.length then json[0] else null) if @_cursor.$one

        json = @selectResults(json, callback)
        if @_cursor.$page or (@_cursor.$page is '')
          callback(null, {
            offset: @_cursor.$offset
            total_rows: @_count(find_query, keys)
            rows: json
          })
        else
          callback(null, json)

      return # terminating

  buildFindQuery: (callback) ->
    queue = new Queue()

    find_query = {}
    for key, value of @_find
      (find_query[key] = value; continue) if (key.indexOf('.') < 0)

      [relation_key, value_key] = key.split('.')
      (find_query[key] = value; continue) if @model_type.relationIsEmbedded(relation_key) # embedded so a nested query is possible in mongo

      # do a join or lookup
      do (relation_key, value_key, value) => queue.defer (callback) =>
        relation = @model_type.relation(relation_key)
        if not relation.join_table and (value_key is 'id')
          find_query["#{relation_key}_#{value_key}"] = value
          callback()

        # TODO: optimize with a one-step join?
        else if relation.join_table or (relation.type is 'belongsTo')
          (related_query = {$values: 'id'})[value_key] = value
          relation.reverse_relation.model_type.cursor(related_query).toJSON (err, related_ids) =>
            return callback(err) if err
            if relation.join_table
              (join_query = {})[relation.reverse_relation.foreign_key] = {$in: related_ids}
              join_query.$values = relation.foreign_key
              relation.join_table.cursor(join_query).toJSON (err, model_ids) =>
                return callback(err) if err
                find_query.id = {$in: model_ids}
                callback()
            else
              find_query[relation.foreign_key] = {$in: related_ids}
              callback()

        # foreign key is on the model
        else
          (related_query = {})[value_key] = value
          related_query.$values = relation.foreign_key
          relation.reverse_relation.model_type.cursor(related_query).toJSON (err, model_ids) =>
            return callback(err) if err
            find_query.id = {$in: model_ids}
            callback()

    queue.await (err) =>
      # console.log "\nmodel_name: #{@model_type.model_name} find_query: #{util.inspect(find_query)}"
      callback(err, find_query)

  fetchIncludes: (json, callback) ->
    # TODO: $select/$values = 'relation.field'
    return callback() unless @_cursor.$include

    load_queue = new Queue(1)

    $include_keys = if _.isArray(@_cursor.$include) then @_cursor.$include else [@_cursor.$include]
    for key in $include_keys
      continue if @model_type.relationIsEmbedded(key)
      return callback(new Error "Included relation '#{key}' is not a relation") unless relation = @model_type.relation(key)

      # Load the included models
      for model_json in json
        do (key, model_json) => load_queue.defer (callback) =>
          relation.cursor(model_json, key).toJSON (err, related_json) ->
            return calback(err) if err
            # console.log "\nkey: #{key}, model_json: #{util.inspect(model_json)}\nrelated_json: #{util.inspect(related_json)}"
            delete model_json[relation.foriegn_key]
            model_json[key] = related_json
            callback()

    load_queue.await callback

  selectResults: (json, callback) ->
    # TODO: OPTIMIZE TO REMOVE 'id' and '_rev' if needed
    if @_cursor.$values
      $values = if @_cursor.$white_list then _.intersection(@_cursor.$values, @_cursor.$white_list) else @_cursor.$values
      if @_cursor.$values.length is 1
        key = @_cursor.$values[0]
        json = if $values.length then ((if item.hasOwnProperty(key) then item[key] else null) for item in json) else _.map(json, -> null)
      else
        json = (((item[key] for key in $values when item.hasOwnProperty(key))) for item in json)
    else if @_cursor.$select
      $select = if @_cursor.$white_list then _.intersection(@_cursor.$select, @_cursor.$white_list) else @_cursor.$select
      json = _.map(json, (item) => _.pick(item, $select))

    else if @_cursor.$white_list
      json = _.map(json, (item) => _.pick(item, @_cursor.$white_list))
    return json

  ##########################################
  # Internal
  ##########################################
  _count: (find_query, keys) ->
    if keys.length
      json_count = _.reduce(@store, ((memo, model_json) => return if _.isEqual(_.pick(model_json, keys), find_query) then memo + 1 else memo), 0)
    else
      json_count = _.size(@store)

  _valueIsMatch: (find_query, key_path, model_json, callback) ->
    key_components = key_path.split('.')
    model_type = @model_type

    next = (err, models_json) =>
      return callback(err) if err
      key = key_components.shift()

      # done conditions
      unless key_components.length
        was_handled = false
        find_value = find_query[key_path]

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
