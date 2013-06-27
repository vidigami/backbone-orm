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

  @renderModelJSON = (related_model, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3
    return callback(null, null) unless related_model

    # pick keys
    if _.isArray(template)
      queue = new Queue()

      result = {}
      for key in template
        do (key) -> queue.defer (callback) ->
          related_model.get key, (err, value) ->
            return callback(err) if err
            result[key] = value
            callback()

      queue.await (err) ->
        return callback(err) if err
        callback(null, result)

    # render template
    else
      template related_model, options, (err, related_json) ->
        return callback(err) if err
        callback(null, related_json)

  @renderModelsJSON = (related_models, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 3

    # many
    queue = new Queue()

    result = []
    for related_model in related_models
      do (related_model) ->
        queue.defer (callback) ->
          JSONUtils.renderModelJSON related_model, template, options, (err, related_json) ->
            return callback(err) if err
            result.push(related_json)
            callback()

    queue.await (err) ->
      return callback(err) if err
      callback(null, result)

  @appendModelJSON = (json, related_model, attribute_name, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 5

    # empty
    (json[attribute_name] = null; return callback()) unless related_model

    JSONUtils.renderModelJSON related_model, template, options, (err, model_json) ->
      return callback(err) if err
      json[attribute_name] = model_json
      callback()

  @appendRelatedJSON = (json, model, attribute_name, template, options, callback) ->
    (callback = options; options = {}) if arguments.length is 5

    model.get attribute_name, (err, related_models) ->
      callback(err) if err

      return JSONUtils.appendModelJSON(json, related_models, attribute_name, template, options, callback) unless _.isArray(related_models) # one

      # many
      JSONUtils.renderModelsJSON related_models, template, options, (err, related_json) ->
        return callback(err) if err
        json[attribute_name] = related_json
        callback()
