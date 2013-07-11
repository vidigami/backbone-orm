util = require 'util'
URL = require 'url'
Backbone = require 'backbone'
_ = require 'underscore'
moment = require 'moment'
inflection = require 'inflection'
Queue = require 'queue-async'

Cursor = require './cursor'

S4 = -> (((1+Math.random())*0x10000)|0).toString(16).substring(1)

BATCH_DEFAULT_LIMIT = 1500
BATCH_DEFAULT_PARALLELISM = 1

INTERVAL_TYPES = ['milliseconds', 'seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years']


module.exports = class Utils
  @bbCallback: (callback) -> return {success: ((model) -> callback(null, model)), error: ((model, err) -> callback(err or new Error("Backbone call failed")))}

  @guid = -> return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())

  # parse an object whose values are still JSON stringified
  @parseValues: (values) ->
    if _.isArray(values)
      return _.map(values, Utils.parseValues)
    else if _.isObject(values)
      result = {}
      result[key] = Utils.parseValues(value) for key, value of values
      return result
    else if _.isString(values)
      if (values.length >= 20) and values[values.length-1] is 'Z'
        date = moment.utc(values)
        return if date and date.isValid() then date.toDate() else values
      else
        return true if values is 'true'
        return false if values is 'false'
        try
          return Utils.parseValues(values) if values = JSON.parse(values)
        catch err
    return values

  @parseUrl: (url) ->
    url_parts = URL.parse(url)
    database_parts = url_parts.pathname.split('/')
    table = database_parts.pop()
    database = database_parts[database_parts.length-1]
    url_parts.pathname = database_parts.join('/')

    result = {
      host: url_parts.hostname
      port: url_parts.port
      database_path: URL.format(url_parts)
      database: database
      table: table
      model_name: inflection.classify(inflection.singularize(table))
    }

    if url_parts.auth
      auth_parts = url_parts.auth.split(':')
      result.user = auth_parts[0]
      result.password = if auth_parts.length > 1 then auth_parts[1] else null

    return result

  ##############################
  # Relational
  ##############################
  @reverseRelation: (model_type, owning_model_name) ->
    return null unless model_type.relation
    reverse_key = inflection.underscore(owning_model_name)
    return relation if relation = model_type.relation(reverse_key = inflection.underscore(owning_model_name)) # singular
    return model_type.relation(inflection.pluralize(reverse_key)) # plural

  @dataId: (data) ->
    if data instanceof Backbone.Model
      return data.get('id')
    else if _.isObject(data)
      return data.id
    return data

  @createJoinTableModel: (relation1, relation2) ->
    model_name1 = inflection.pluralize(inflection.underscore(relation1.model_type.model_name))
    model_name2 = inflection.pluralize(inflection.underscore(relation2.model_type.model_name))
    table = if model_name1.localeCompare(model_name2) < 0 then "#{model_name1}_#{model_name2}" else "#{model_name2}_#{model_name1}"

    schema = {}
    schema[relation1.foreign_key] = ['Integer', indexed: true]
    schema[relation2.foreign_key] = ['Integer', indexed: true]

    class JoinTable extends Backbone.Model
      urlRoot: "#{Utils.parseUrl(_.result(relation1.model_type.prototype, 'url')).database_path}/#{table}"
      @schema: schema
      sync: relation1.model_type.createSync(JoinTable)

    return JoinTable

  ##############################
  # Sorting
  ##############################
  @isSorted: (models, fields) ->
    fields = _.uniq(fields)
    for model in models
      return false if last_model and @fieldCompare(last_model, model, fields) is 1
      last_model = model
    return true

  @fieldCompare: (model, other_model, fields) ->
    field = fields[0]
    field = field[0] if _.isArray(field) # for mongo

    if field.charAt(0) is '-'
      field = field.substr(1)
      desc = true
    if model.get(field) == other_model.get(field)
      return if fields.length > 1 then @fieldCompare(model, other_model, fields.splice(1)) else 0
    if desc
      return if model.get(field) < other_model.get(field) then 1 else -1
    else
      return if model.get(field) > other_model.get(field) then 1 else -1

  @jsonFieldCompare: (model, other_model, fields) ->
    field = fields[0]
    field = field[0] if _.isArray(field) # for mongo

    if field.charAt(0) is '-'
      field = field.substr(1)
      desc = true
    if model[field] == other_model[field]
      return if fields.length > 1 then @jsonFieldCompare(model, other_model, fields.splice(1)) else 0
    if desc
      return if JSON.stringify(model[field]) < JSON.stringify(other_model[field]) then 1 else -1
    else
      return if JSON.stringify(model[field]) > JSON.stringify(other_model[field]) then 1 else -1

  ##############################
  # Batch
  ##############################
  @batch: (model_type, query, options, callback, fn) ->
    [query, options, callback, fn] = [{}, {}, query, options] if arguments.length is 3
    [query, options, callback, fn] = [{}, query, options, callback] if arguments.length is 4

    processed_count = 0
    parsed_query = Cursor.parseQuery(query)
    parallelism = if options.hasOwnProperty('parallelism') then options.parallelism else BATCH_DEFAULT_PARALLELISM
    method = options.method or 'toModels'

    runBatch = (batch_cursor, callback) ->
      cursor = model_type.cursor(batch_cursor)
      cursor[method].call cursor, (err, models) ->
        return callback(new Error("Failed to get models. Error: #{err}")) if err or !models
        return callback(null, processed_count) unless models.length

        # batch operations on each
        queue = new Queue(parallelism)
        for model in models
          do (model) -> queue.defer (callback) -> fn(model, callback)
          processed_count++
          break if parsed_query.cursor.$limit and (processed_count >= parsed_query.cursor.$limit)
        queue.await (err) ->
          return callback(err) if err
          return callback(null, processed_count) if parsed_query.cursor.$limit and (processed_count >= parsed_query.cursor.$limit)
          batch_cursor.$offset += batch_cursor.$limit
          runBatch(batch_cursor, callback)

    batch_cursor = _.extend({
      $limit: options.$limit or BATCH_DEFAULT_LIMIT
      $offset: parsed_query.$offset or 0
      $sort: parsed_query.$sort or 'id' # TODO: generalize sort for different types of sync
    }, parsed_query.find) # add find parameters
    runBatch(batch_cursor, callback)


  ##############################
  # Interval
  ##############################
  @interval: (model_type, query, options, callback, fn) ->
    [query, options, callback, fn] = [{}, {}, query, options] if arguments.length is 3
    [query, options, callback, fn] = [{}, query, options, callback] if arguments.length is 4

    throw new Error 'missing option: key' unless key = options.key
    throw new Error 'missing option: type' unless options.type
    throw new Error("type is not recognized: #{options.type}, #{_.contains(INTERVAL_TYPES, options.type)}") unless _.contains(INTERVAL_TYPES, options.type)
    iteration_info = _.clone(options)
    iteration_info.range = {} unless iteration_info.range
    range = iteration_info.range
    no_models = false

    queue = new Queue(1)

    # start
    queue.defer (callback) ->
      # find the first record
      unless start = (range.$gte or range.$gt)
        model_type.cursor(query).limit(1).sort(key).toModels (err, models) ->
          return callback(err) if err
          (no_models = true; return callback()) unless models.length
          range.start = iteration_info.first = models[0].get(key)
          callback()

      # find the closest record to the start
      else
        range.start = start
        model_type.findOneNearestDate start, {key: key, reverse: true}, query, (err, model) ->
          return callback(err) if err
          (no_models = true; return callback()) unless model
          iteration_info.first = model.get(key)
          callback()

    # end
    queue.defer (callback) ->
      return callback() if no_models

      # find the last record
      unless end = (range.$lte or range.$lt)
        model_type.cursor(query).limit(1).sort("-#{key}").toModels (err, models) ->
          return callback(err) if err
          (no_models = true; return callback()) unless models.length
          range.end = iteration_info.last = models[0].get(key)
          callback()

      # find the closest record to the end
      else
        range.end = end
        model_type.findOneNearestDate end, {key: key}, query, (err, model) ->
          return callback(err) if err
          (no_models = true; return callback()) unless model
          iteration_info.last = model.get(key)
          callback()

    # process
    queue.await (err) ->
      return callback(err) if err
      return callback() if no_models

      # interval length
      start_ms = range.start.getTime()
      length_ms = moment.duration((if _.isUndefined(options.length) then 1 else options.length), options.type).asMilliseconds()
      throw Error("length_ms is invalid: #{length_ms} for range: #{util.inspect(range)}") unless length_ms

      query = _.clone(query)
      query.$sort = [key]
      processed_count = 0
      iteration_info.index = 0

      runInterval = (current) ->
        return callback() if current.isAfter(range.end) # done

        # find the next entry
        query[key] = {$gte: current.toDate(), $lte: iteration_info.last}
        model_type.findOne query, (err, model) ->
          return callback(err) if err
          return callback() unless model # done

          # skip to next
          next = model.get(key)
          iteration_info.index = Math.floor((next.getTime() - start_ms) / length_ms)

          current = moment.utc(range.start).add({milliseconds: iteration_info.index * length_ms})
          iteration_info.start = current.toDate()
          next = current.clone().add({milliseconds: length_ms})
          iteration_info.end = next.toDate()

          query[key] = {$gte: current.toDate(), $lt: next.toDate()}
          fn query, iteration_info, (err) ->
            return callback(err) if err
            runInterval(next)

      runInterval(moment(range.start))
