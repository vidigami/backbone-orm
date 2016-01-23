###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'

Queue = require './lib/queue'
Utils = require './lib/utils'
JSONUtils = require './lib/json_utils'
DateUtils = require './lib/date_utils'
Cursor = require './lib/cursor'

IS_MATCH_FNS =
  $ne: (mv, tv) -> return not _.isEqual(mv, tv)

  $lt: (mv, tv) ->
    throw Error 'Cannot compare to null' if _.isNull(tv)
    return (if _.isDate(tv) then DateUtils.isBefore(mv, tv) else mv < tv)

  $lte: (mv, tv) ->
    throw Error 'Cannot compare to null' if _.isNull(tv)
    return if _.isDate(tv) then !DateUtils.isAfter(mv, tv) else (mv <= tv)

  $gt: (mv, tv) ->
    throw Error 'Cannot compare to null' if _.isNull(tv)
    return (if _.isDate(tv) then DateUtils.isAfter(mv, tv) else mv > tv)

  $gte: (mv, tv) ->
    throw Error 'Cannot compare to null' if _.isNull(tv)
    return if _.isDate(tv) then !DateUtils.isBefore(mv, tv) else (mv >= tv)

  $exists: (mv, tv) -> if !tv then _.isUndefined(mv) else not _.isUndefined(mv)

IS_MATCH_OPERATORS = _.keys(IS_MATCH_FNS)

# @nodoc
# TODO: handle merging of non-array types (eg. $lt, $ne)
valueToArray = (value) -> return (if _.isArray(value) then value else (if _.isNull(value) then [] else (if value.$in then value.$in else [value])))
mergeQuery = (query, key, value) ->
  query[key] = if query.hasOwnProperty(key) then {$in: _.intersection(valueToArray(query[key]), valueToArray(value))} else value

# @private
module.exports = class MemoryCursor extends Cursor
  queryToJSON: (callback) ->
    return callback(null, if @hasCursorQuery('$one') then null else []) if @hasCursorQuery('$zero')

    exists = @hasCursorQuery('$exists')

    @buildFindQuery (err, find_query) =>
      return callback(err) if err

      json = [] # NOTE: we need to clone the data out of the store since the caller could modify it
      keys = null
      queue = new Queue(1)

      queue.defer (callback) =>
        [ins, nins] = [{}, {}]
        for key, value of find_query
          (delete find_query[key]; ins[key] = value.$in) if value?.$in
          (delete find_query[key]; nins[key] = value.$nin) if value?.$nin
        [ins_is_empty, nins_is_empty] = [JSONUtils.isEmptyObject(ins), JSONUtils.isEmptyObject(nins)]
        keys = _.keys(find_query)

        # use find
        if keys.length or !ins_is_empty or !nins_is_empty
          if @_cursor.$ids
            for model_json in @store
              json.push(JSONUtils.deepClone(model_json)) if (model_json.id in @_cursor.$ids) and _.isEqual(_.pick(model_json, keys), find_query)
            callback()

          else
            # console.log "\nmodel: #{@model_type.model_name} find_query: #{JSONUtils.stringify(find_query)} @store: #{JSONUtils.stringify(@store)}"

            Utils.each @store, ((model_json, callback) =>
              return callback(null, true) if exists and json.length # exists only needs one result
              (return callback() for key, values of ins when model_json[key] not in values) if !ins_is_empty
              (return callback() for key, values of nins when model_json[key] in values) if !nins_is_empty

              is_match = true
              Utils.eachDone keys, ((key, callback) => @_valueIsMatch find_query, key, model_json, (err, _is_match) =>
                callback(err, !(is_match = _is_match))
              ), (err) =>
                err or !is_match or json.push(JSONUtils.deepClone(model_json))
                callback(err)
            ), callback

        else
          # filter by ids
          if @_cursor.$ids
            json = (JSONUtils.deepClone(model_json) for model_json in @store when (model_json.id in @_cursor.$ids))
          else
            json = (JSONUtils.deepClone(model_json) for model_json in @store)
          callback()

      if not exists
        queue.defer (callback) =>
          if @_cursor.$sort
            $sort_fields = if _.isArray(@_cursor.$sort) then @_cursor.$sort else [@_cursor.$sort]
            json.sort (model, next_model) => Utils.jsonFieldCompare(model, next_model, $sort_fields)

          # TODO: optimize by combining sort and find, storing one result instead of processing the whole list and then reducing
          if @_cursor.$unique
            unique_json = []
            unique_keys = {}
            for model_json in json
              key = ''
              key += "#{field}:#{JSON.stringify(model_json[field])}" for field in @_cursor.$unique when model_json.hasOwnProperty(field)
              continue if unique_keys[key]
              unique_keys[key] = true
              unique_json.push(model_json)
            json = unique_json

          if @_cursor.$offset
            number = json.length - @_cursor.$offset
            number = 0 if number < 0
            json = if number then json.slice(@_cursor.$offset, @_cursor.$offset+number) else []

          if @_cursor.$one
            json = json.slice(0, 1)

          else if @_cursor.$limit
            json = json.splice(0, Math.min(json.length, @_cursor.$limit))
          callback()

        queue.defer (callback) => @fetchIncludes(json, callback)

      queue.await =>
        return callback(null, (if _.isArray(json) then json.length else (if json then 1 else 0))) if @hasCursorQuery('$count')
        return callback(null, (if _.isArray(json) then !!json.length else json)) if exists

        if @hasCursorQuery('$page')
          count_cursor = new MemoryCursor(_.extend(_.pick(@_cursor, '$unique'), @_find), _.pick(@, ['model_type', 'store']))
          count_cursor.count (err, count) =>
            return callback(err) if err
            callback(null, {
              offset: @_cursor.$offset or 0
              total_rows: count
              rows: @selectResults(json)
            })
        else
          callback(null, @selectResults(json))

      return # terminating

  buildFindQuery: (callback) ->
    queue = new Queue()

    find_query = {}
    for key, value of @_find
      if (key.indexOf('.') < 0)
        (mergeQuery(find_query, key, value); continue) unless reverse_relation = @model_type.reverseRelation(key)
        (mergeQuery(find_query, key, value); continue) if not reverse_relation.embed and not reverse_relation.join_table
        do (key, value, reverse_relation) => queue.defer (callback) =>
          if reverse_relation.embed

            # TODO: should a cursor be returned instead of a find_query?
            throw Error "Embedded find is not yet supported. @_find: #{JSONUtils.stringify(@_find)}"

            (related_query = {}).id = value
            reverse_relation.model_type.cursor(related_query).toJSON (err, models_json) =>
              return callback(err) if err
              mergeQuery(find_query, '_json', (model_json[reverse_relation.key] for model_json in models_json))
              callback()
          else
            (related_query = {})[key] = value
            related_query.$values = reverse_relation.reverse_relation.join_key
            reverse_relation.join_table.cursor(related_query).toJSON (err, model_ids) =>
              return callback(err) if err
              mergeQuery(find_query, 'id', {$in: model_ids})
              callback()
        continue

      [relation_key, value_key] = key.split('.')
      (mergeQuery(find_query, key, value); continue) if @model_type.relationIsEmbedded(relation_key) # embedded so a nested query is possible in mongo

      # do a join or lookup
      do (relation_key, value_key, value) => queue.defer (callback) =>
        (mergeQuery(find_query, key, value); return callback()) unless relation = @model_type.relation(relation_key) # assume embedded

        if not relation.join_table and (value_key is 'id')
          mergeQuery(find_query, relation.foreign_key, value)
          return callback()

        # TODO: optimize with a one-step join?
        else if relation.join_table or (relation.type is 'belongsTo')
          (related_query = {$values: 'id'})[value_key] = value
          relation.reverse_relation.model_type.cursor(related_query).toJSON (err, related_ids) =>
            return callback(err) if err

            if relation.join_table
              (join_query = {})[relation.reverse_relation.join_key] = {$in: related_ids}
              join_query.$values = relation.foreign_key
              relation.join_table.cursor(join_query).toJSON (err, model_ids) =>
                return callback(err) if err
                mergeQuery(find_query, 'id', {$in: model_ids})
                callback()
            else
              mergeQuery(find_query, relation.foreign_key, {$in: related_ids})
              callback()

        # foreign key is on this model
        else
          (related_query = {})[value_key] = value
          related_query.$values = relation.foreign_key
          relation.reverse_model_type.cursor(related_query).toJSON (err, model_ids) =>
            return callback(err) if err
            mergeQuery(find_query, 'id', {$in: model_ids})
            callback()

    queue.await (err) =>
      # console.log "\nmodel_name: #{@model_type.model_name} find_query: #{JSONUtils.stringify(find_query)} find: #{JSONUtils.stringify(@_find)}"
      callback(err, find_query)

  fetchIncludes: (json, callback) ->
    # TODO: $select/$values = 'relation.field'
    return callback() unless @_cursor.$include

    load_queue = new Queue(1)

    include_keys = if _.isArray(@_cursor.$include) then @_cursor.$include else [@_cursor.$include]
    for key in include_keys
      continue if @model_type.relationIsEmbedded(key)
      return callback(new Error "Included relation '#{key}' is not a relation") unless relation = @model_type.relation(key)

      # TODO: optimize by grouping included keys, fetching once, and then updating all relationships
      # Load the included models
      for model_json in json
        do (key, model_json) => load_queue.defer (callback) =>
          relation.cursor(model_json, key).toJSON (err, related_json) ->
            return callback(err) if err
            # console.log "\nkey: #{key}, model_json: #{JSONUtils.stringify(model_json)}\nrelated_json: #{JSONUtils.stringify(related_json)}"
            delete model_json[relation.foriegn_key]
            model_json[key] = related_json
            callback()

    load_queue.await callback

  # @nodoc
  _valueIsMatch: (find_query, key_path, model_json, callback) ->
    model_type = @model_type
    find_value = find_query[key_path]
    (operators = (operator for operator in IS_MATCH_OPERATORS when find_value.hasOwnProperty(operator))) if _.isObject(find_value)
    key_components = key_path.split('.')

    isMatch = (model_json, key) ->
      model_value = model_json[key]
      if operators and operators.length # an object might specify $lt, $lte, $gt, $gte, $ne
        return false for operator in operators when !IS_MATCH_FNS[operator](model_value, find_value[operator])
        return true
      return _.isEqual(model_value, find_value)

    # early out
    return return callback(null, isMatch(model_json, key_components[0])) if key_components.length is 1

    next = (err, model_json) =>
      return callback(err) if err
      key = key_components.shift()
      key = @model_type::idAttribute if key is 'id' # allow for id key override

      # keep traversing relations
      if key_components.length
        return relation.cursor(model_json, key).toJSON(next) if (relation = model_type.relation(key)) and not relation.embed
        return next(null, model_json[key])

      # check final value
      else
        return callback(null, isMatch(model_json, key)) if not _.isArray(model_json)
        return callback(null, true) for json in model_json when isMatch(json, key)
        return callback(null, false)

    next(null, model_json) # start checking
