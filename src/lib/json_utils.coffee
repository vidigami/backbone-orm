###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
Queue = require './queue'
IterationUtils = require './iteration_utils'

module.exports = class JSONUtils

  # @nodoc
  @stringify: (json) -> try return JSON.stringify(json) catch err then return 'Failed to stringify'

  # @nodoc
  @isEmptyObject: (obj) -> return false for key of obj; return true

  # Parse an object whose values are still JSON.
  #
  # @examples
  #   date = JSONUtils.parseDates('2014-08-21T17:48:01.971Z')
  #   array = JSONUtils.parseDates(['2014-08-21T17:48:01.971Z', '2014-08-21T17:48:01.971Z'])
  #   object = JSONUtils.parseDates({created_at: '2014-08-21T17:48:01.971Z', changes: ['2014-08-21T17:48:01.971Z', '2014-08-21T17:48:01.971Z']})
  #
  @parseDates: (json) ->
    if _.isString(json)
      # Date: A trailing 'Z' means that the date will _always_ be parsed as UTC
      return date if (json.length >= 20) and json[json.length-1] is 'Z' and not _.isNaN((date = new Date(json)).getTime())
    else if _.isObject(json) or _.isArray(json)
      json[key] = JSONUtils.parseDates(value) for key, value of json
    return json

  # Parse an object whose values are still JSON .
  #
  # @example
  #   id = JSONUtils.parseField(csv_column[0], MyModel, 'id')
  #
  @parseField: (value, model_type, key) ->
    return JSONUtils.parseDates(value) unless model_type?.schema().idType(key) is 'Integer'
    return integer_value unless _.isNaN(integer_value = +value)
    console.log "Warning: failed to convert key: #{key} value: #{value} to integer. Model: #{model_type.model_name}"
    return value

  # Parse an object whose values types need to be inferred.
  #
  # @example
  #   object = JSONUtils.parse({id: csv_column[0], created_at: csv_column[1]}, MyModel)
  #   array = JSONUtils.parse([{id: csv_column[0], created_at: csv_column[1]]}, MyModel)
  #
  @parse: (obj, model_type) ->
    return JSONUtils.parseDates(obj) unless _.isObject(obj)
    return (JSONUtils.parse(value, model_type) for value in obj) if _.isArray(obj)
    result = {}
    result[key] = JSONUtils.parseField(value, model_type, key) for key, value of obj
    return result

  # Deserialze a strict-JSON query to a json format
  #
  # @example
  #   json = JSONUtils.parseQuery(query)
  #
  @parseQuery: (query) ->
    json = {}
    for key, value of query
      json[key] = value
      if _.isString(value) and value.length # needs parsing
        try value = JSON.parse(value) # BE FORGIVING AND ALLOW FOR NON-QUOTED STRINGS DESPITE THE RISK OF INTEGER LOOKING STRINGS LIKE "12683162e63": catch err then console.log "Failed to JSON.parse query key: #{key} value: #{value}. Missing quotes on a string? Error: #{err.message}"
        json[key] = JSONUtils.parseDates(value)
    return json

  # Serialze json to a strict-JSON query format
  #
  # @example
  #   query = JSONUtils.querify(json)
  #
  @querify: (json) ->
    query = {}
    query[key] = JSON.stringify(value) for key, value of json
    return query

  @toQuery: (json) -> console.log "JSONUtils.toQuery has been deprecated. Use JSONUtils.querify instead"

  # Render a template that can be a key, keys, DSL object, or function.
  #
  # @example: render a key
  #   JSONUtils.renderTemplate model, 'name', callback
  #
  # @example: render multiple keys
  #   JSONUtils.renderTemplate model, ['id', 'name'], callback
  #
  # @example: render a DSL object
  #   JSONUtils.renderTemplate model, {$select: ['id', 'name']}
  #
  # @example: render a template
  #   JSONUtils.renderTemplate model, ((model, render_options, callback) -> callback(null, _.pick(model.attributes, 'id', 'name')), callback
  #
  @renderTemplate = (models, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3

    # one
    unless _.isArray(models)
      return callback(null, null) unless models

      # Single field
      return JSONUtils.renderKey(models, template, options, callback) if _.isString(template)

      # Array of fields, pick keys
      return JSONUtils.renderKeys(models, template, options, callback) if _.isArray(template)

      # Render template function
      return template(models, options, callback) if _.isFunction(template)

      # dsl object
      return JSONUtils.renderDSL(models, template, options, callback)

    # many
    else
      results = []

      # Render in series to preserve order - a better way would be nice
      IterationUtils.each models, ((model, callback) =>
        JSONUtils.renderTemplate model, template, options, (err, related_json) -> err or results.push(related_json); callback(err)
      ), (err) -> if err then callback(err) else callback(null, results)

  # @private
  @renderDSL = (model, dsl, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3

    queue = new Queue()
    result = {}
    for key, args of dsl
      do (key, args) -> queue.defer (callback) ->
        field = args.key or key

        if relation = model.relation(field)
          # classroom:      {$select: ['id', 'name']}                     -> dsl
          # a_class:        {key: 'classroom', $select: ['id', 'name']}   -> dsl
          # classroom:      {query: {year: '2012'}}                      -> query
          # total_greats:   {key: 'greats', query: {$count: true}}       -> query

          if args.query
            query = args.query
            template = args.template
          else if args.$count
            query = _.clone(args)
            delete query.key
          else if _.isFunction(args)
            template = args
          else if args.template
            if _.isObject(args.template) and not _.isFunction(args.template)
              query = args.template
            else
              template = args.template
              query = _.clone(args)
              delete query.key; delete query.template
              query = null if JSONUtils.isEmptyObject(query)
          else
            template = _.clone(args)
            delete template.key

          # template
          if template
            if query
              relation.cursor(model, field, query).toModels (err, models) ->
                return callback(err) if err
                JSONUtils.renderTemplate models, template, options, (err, json) -> result[key] = json; callback(err)

            else
              model.get field, (err, related_model) ->
                return callback(err) if err
                JSONUtils.renderTemplate related_model, template, options, (err, json) -> result[key] = json; callback(err)

          # query
          else
            relation.cursor(model, field, query).toJSON (err, json) -> result[key] = json; callback(err)

        else

          if key.length > 1 and key[key.length-1] is '_'
            key = key[0..key.length-2]

          if key is '$select'
            if _.isString(args)
              JSONUtils.renderKey model, args, options, (err, json) -> result[args] = json; callback(err)
            else
              JSONUtils.renderKeys model, args, options, (err, json) -> _.extend(result, json); callback(err)

            # full_name:      'name'
          else if _.isString(args)
            JSONUtils.renderKey model, args, options, (err, json) -> result[key] = json; callback(err)

            # can_delete: (photo, options, callback) ->
          else if _.isFunction(args)
            args model, options, (err, json) -> result[key] = json; callback(err)

            # is_great: {method: 'isGreatFor', args: [options.user]}
          else if _.isString(args.method)
            fn_args = if _.isArray(args.args) then args.args.slice() else (if args.args then [args.args] else [])
            fn_args.push((err, json) -> result[key] = json; callback(err))
            model[args.method].apply(model, fn_args)

          else
            console.trace "Unknown DSL action: #{key}: ", args
            return callback(new Error "Unknown DSL action: #{key}: ", args)

    queue.await (err) -> callback(err, if err then undefined else result)

  # Render a list of keys from a model to json: ['key', 'key_two', ..]
  # @private
  @renderKeys = (model, keys, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3

    result = {}
    queue = new Queue()
    for key in keys
      do (key) -> queue.defer (callback) ->
        JSONUtils.renderKey model, key, options, (err, value) ->
          return callback(err) if err
          result[key] = value
          callback()
    queue.await (err) -> callback(err, if err then undefined else result)

  # Render a single key friom a model to json: model.get('key')
  # @private
  @renderKey = (model, key, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3

    model.get key, (err, value) ->
      return callback(err) if err

      # Related models need to be converted to json
      if model.relation(key)
        return callback(null, (item.toJSON() for item in value)) if _.isArray(value)
        return callback(null, value = value.toJSON()) if value and value.toJSON
      callback(null, value)

  # Render a Model or Collection relationship
  @renderRelated = (models, attribute_name, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 4

    # one
    unless _.isArray(models)
      models.get attribute_name, (err, related_models) ->
        callback(err) if err
        JSONUtils.renderTemplate(related_models, template, options, callback)

    # many
    else
      results = []
      queue = new Queue()
      for model in models
        do (model) -> queue.defer (callback) ->
          model.get attribute_name, (err, related_models) ->
            callback(err) if err

            JSONUtils.renderTemplate related_models, template, options, (err, related_json) ->
              return callback(err) if err

              results.push(related_json)
              callback()

      queue.await (err) -> callback(err, if err then undefined else results)

  @deepClone = (obj, depth) =>
    return obj if not obj or (typeof obj isnt 'object')   # a value
    return String::slice.call(obj) if _.isString(obj)     # a string
    return new Date(obj.getTime()) if _.isDate(obj)       # a date
    return obj.clone() if _.isFunction(obj.clone)         # a specialized clone function

    if _.isArray(obj)                                     # an array
      clone = Array::slice.call(obj)
    else if obj.constructor isnt {}.constructor           # a reference
      return obj
    else                                                  # an object
      clone = _.extend({}, obj)

    # keep cloning deeper
    ((clone[key] = @deepClone(clone[key], depth - 1)) for key of clone) if not _.isUndefined(depth) and (depth > 0)

    return clone
