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
      return models.get(template, callback) if _.isString(template)

      # Array of fields, pick keys
      return JSONUtils.renderJSONKeys(models, template, options, callback) if _.isArray(template)

      # Render template function
      return template(models, options, callback) if _.isFunction(template)

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

        # can_delete: {fn: (photo, options, callback) -> }
        if _.isFunction(args.fn)
          queue.defer (callback) ->
            template = _.extend({}, args, fn: undefined)
            args.fn model, options, (err, json) ->
              result[key] = json
              callback()

        # is_great: fn: 'isGreatFor', args: [options.user]}
        else if args.fn
          queue.defer (callback) ->
            args.args or= []
            args.args = [args.args] unless _.isArray(args.args)
            args.args.push((err, json) -> result[key] = json; callback())
            model[args.fn].apply(model, args.args)

        # total_greats:   {key: 'greats', $count: true}
        # classroom:      {$select: ['id', 'name']}
        # full_name:      'name'
        else
          if args.key
            field = args.key
            delete args.key
          else if _.isString(args)
            field = args
            args = {}
          else
            field = key
            args = {}

          if relation = model.relation(field)
            queue.defer (callback) ->
              relation.cursor(model, field, args).toJSON (err, value) ->
                return callback(err) if err
                result[key] = value
                callback()
          else
            queue.defer (callback) ->
              model.get field, (err, value) ->
                return callback(err) if err
                result[key] = value
                callback()

    queue.await (err) ->
      return callback(err) if err
      callback(null, result)

  @renderJSONKeys = (model, keys, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3

    queue = new Queue()
    result = {}

    for key in keys
      do (key) ->
        queue.defer (callback) ->
          # TODO allow for json or models
          model.get key, (err, value) ->
            return callback(err) if err
            result[key] = value
            callback()

    queue.await (err) ->
      return callback(err) if err
      callback(null, result)

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
