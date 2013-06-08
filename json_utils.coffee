_ = @_ or require 'underscore'
moment = @moment or require 'moment'

module.exports = class JSONUtils

  @JSONToValue: (json) ->
    return json unless json
    if _.isDate(json)
      return json
    else if _.isString(json) and (json.length > 20) and json[json.length-1] is 'Z'
      date = moment.utc(json)
      return if date and date.isValid() then date.toDate() else json
    else if _.isString(json)
      return json
    else if _.isArray(json)
      json[index] = @JSONToValue(value) for index, value of json
    else if _.isObject(json)
      json[key] = @JSONToValue(value) for key, value of json
    return json

  @valueToJSON: (value) ->
    return value unless value
    if _.isDate(value)
      try
        return value.toISOString()
      catch e
        return null # not a valid date
    else if _.isString(value)
      return value
    else if _.isArray(value)
      value[index] = @JSONToValue(item) for index, item of value
    else if _.isObject(value)
      value[key] = @valueToJSON(item) for key, item of value
    return value