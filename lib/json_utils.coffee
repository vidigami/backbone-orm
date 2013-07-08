util = require 'util'
_ = require 'underscore'
moment = require 'moment'
Queue = require 'queue-async'

module.exports = class JSONUtils

  @JSONToValue: (json) ->
    return json unless json
    if _.isDate(json)
      return json
    else if _.isString(json) and (json.length > 20) and json[json.length-1] is 'Z'
      date = moment.utc(json)
      return if date and date.isValid() then date.toDate() else json
    else if _.isString(json)
      return true if json is 'true'
      return false if json is 'false'
      return json
    else if _.isArray(json)
      json[index] = @JSONToValue(value) for index, value of json
    else if _.isObject(json)
      json[key] = @JSONToValue(value) for key, value of json
    return json

  @valueToJSON: (value) ->
    return value unless value
    if value.toJSON
      return value.toJSON()
    else if _.isString(value)
      return value
    else if _.isArray(value)
      value[index] = @JSONToValue(data) for index, data of value
    else if _.isObject(value)
      value[key] = @valueToJSON(data) for key, data of value
    return value

  # template formats: 'field', ['field', ..], template dsl { }, function()
  # TODO allow for json or models
  @renderJSON = (models, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3

    # one
    unless _.isArray(models)
      return callback(null, null) unless models

      # Single field
      return JSONUtils.renderJSONKey(models, template, options, callback) if _.isString(template)

      # Array of fields, pick keys
      return JSONUtils.renderJSONKeys(models, template, options, callback) if _.isArray(template)

      # Render template function
      if _.isFunction(template) or _.isFunction(template.fn)
        fn = if template.fn then template.fn else template
        return fn(models, options, callback)

      # dsl object
      return JSONUtils.renderJSONDSL(models, template, options, callback)

    # many
    else
      queue = new Queue()

      result = []
      for model in models
        do (model) ->
          queue.defer (callback) ->
            JSONUtils.renderJSON model, template, options, (err, related_json) ->
              return callback(err) if err
              result.push(related_json)
              callback()

      queue.await (err) ->
        return callback(err) if err
        callback(null, result)

  @renderJSONDSL = (model, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3

    queue = new Queue()
    result = {}
    if template.$select
      queue.defer (callback) ->
        JSONUtils.renderJSONKeys model, template.$select, options, (err, related_json) ->
          return callback(err) if err
          result = related_json
          callback()

    for key, args of template
      continue if key is '$select'

      do (key, args) ->
        field = if args.key then args.key else key
        relation = model.relation(field)

        # full_name:      'name'
        if _.isString(args)
          queue.defer (callback) ->
            JSONUtils.renderJSONKey model, args, options, (err, value) ->
              return callback(err) if err
              result[key] = value
              callback()

        else if relation
          # classroom:      {$select: ['id', 'name']}                     -> dsl
          # a_class:        {key: 'classroom', $select: ['id', 'name']}   -> dsl
          # a_class:        {key: 'classroom', fn: (model, options, callback) -> )}   -> dsl
          # classroom:      {$query: {year: '2012'}}                      -> query
          # total_greats:   {key: 'greats', $query: {$count: true}}       -> query
          queue.defer (callback) ->

            # query
            if args.$query
              return callback("Template $query provided for a field that isn't a relation: #{field}") unless relation
              relation.cursor(model, field, args.$query).toJSON (err, value) ->
                return callback(err) if err
                result[key] = value
                callback()
            # dsl
            else
              return callback("Template provided for a field that isn't a relation: #{field}") unless relation
              model.get field, (err, related_model) ->
                return callback(err) if err
                # Clone the args so we don't clobber the key if we're using it for more than one model
                render_args = _.extend({}, args)
                delete render_args['key']
                JSONUtils.renderJSON related_model, render_args, (err, value) ->
                  return callback(err) if err
                  result[key] = value
                  callback()

        # can_delete: {fn: (photo, options, callback) -> }
        else if _.isFunction(args.fn)
          queue.defer (callback) ->
            args.fn model, options, (err, json) ->
              result[key] = json
              callback()

        # is_great: {fn: 'isGreatFor', args: [options.user]}
        else if args.fn
          queue.defer (callback) ->
            fn_args = if _.isArray(args.args) then args.args.slice() else (if args.args then [args.args] else [])
            fn_args.push((err, json) -> result[key] = json; callback())
            model[args.fn].apply(model, fn_args)

    queue.await (err) ->
      return callback(err) if err
      callback(null, result)

  # Render a list of keys from a model to json: ['key', 'key_two', ..]
  @renderJSONKeys = (model, keys, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3

    queue = new Queue()
    result = {}
    for key in keys
      do (key) ->
        queue.defer (callback) ->
          JSONUtils.renderJSONKey model, key, options, (err, value) ->
            return callback(err) if err
            result[key] = value
            callback()

    queue.await (err) ->
      return callback(err) if err
      callback(null, result)

  # Render a single key friom a model to json: model.get('key')
  @renderJSONKey = (model, key, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3
    model.get key, (err, value) ->
      return callback(err) if err
      # Related models need to be converted to json
      if model.relation(key)
        if _.isArray(value)
          #todo: check bug, incorrect models are being returned, they contain themselves? {0:model, 1: model, <correct model fields are here>}
          value = (val.toJSON() for val in value)
        else
          value = value.toJSON()
      callback(null, value)

  @appendJSON = (json, related_model, attribute_name, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 5

    # empty
    (json[attribute_name] = null; return callback()) unless related_model

    JSONUtils.renderJSON related_model, template, options, (err, model_json) ->
      return callback(err) if err
      json[attribute_name] = model_json
      callback()

  @appendRelatedJSON = (json, model, attribute_name, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 5

    model.get attribute_name, (err, related_models) ->
      callback(err) if err

      JSONUtils.renderJSON related_models, template, options, (err, related_json) ->
        return callback(err) if err
        json[attribute_name] = related_json
        callback()
