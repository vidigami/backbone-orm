###
  backbone-orm.js 0.5.10
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
###

_ = require 'underscore'
moment = require 'moment'
Queue = require './queue'

module.exports = class JSONUtils

  # Parse an a request's parameters whose values are still JSON stringified (for example, ids as strings).
  #
  # @example
  #   method: (req, res) ->
  #     params = JSONUtils.parseParams(req.params)
  #
  @parseParams: (params) ->
    result = {}
    result[key] = JSON.parse(value) for key, value of params
    return result

  # Parse an object whose values are still JSON stringified (for example, dates as strings in ISO8601 format).
  #
  # @example
  #   method: (req, res) ->
  #     query = JSONUtils.parse(req.query)
  #
  @parse: (values) ->
    return null if _.isNull(values) or (values is 'null')
    return values if _.isDate(values)
    return _.map(values, JSONUtils.parse) if _.isArray(values)
    if _.isObject(values)
      result = {}
      result[key] = JSONUtils.parse(value) for key, value of values
      return result
    else if _.isString(values)
      # Date
      if (values.length >= 20) and values[values.length-1] is 'Z'
        date = moment.utc(values)
        return if date and date.isValid() then date.toDate() else values

      # Boolean
      return true if values is 'true'
      return false if values is 'false'

      return match[0] if match = /^\"(.*)\"$/.exec(values) # "quoted string"

      # stringified JSON
      try
        return JSONUtils.parse(values) if values = JSON.parse(values)
      catch err
    return values

  # Serialze json to a toQuery format. Note: the caller should use encodeURIComponent on all keys and values when added to URL
  #
  # @example
  #   query = JSONUtils.toQuery(json)
  #
  @toQuery: (values, depth=0) ->
    return 'null' if _.isNull(values)
    return JSON.stringify(values) if _.isArray(values)
    return values.toJSON() if _.isDate(values) or values.toJSON
    if _.isObject(values)
      return JSON.stringify(values) if depth > 0
      result = {}
      result[key] = JSONUtils.toQuery(value, 1) for key, value of values
      return result
    return values

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
      queue = new Queue(1)
      for model in models
        do (model) -> queue.defer (callback) ->
          JSONUtils.renderTemplate model, template, options, (err, related_json) ->
            return callback(err) if err
            results.push(related_json)
            callback()
      queue.await (err) -> callback(err, if err then undefined else results)

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
              query = null if _.size(query) is 0
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
            fn_args.push((err, json) -> result[key] = json; callback())
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
    return new Date(obj.valueOf()) if _.isDate(obj)       # a date
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
