util = require 'util'
URL = require 'url'
Backbone = require 'backbone'
_ = require 'underscore'
moment = require 'moment'
inflection = require 'inflection'
Queue = require 'queue-async'

S4 = -> (((1+Math.random())*0x10000)|0).toString(16).substring(1)

BATCH_DEFAULT_LIMIT = 1500
BATCH_DEFAULT_PARALLELISM = 1

INTERVAL_TYPES = ['milliseconds', 'seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years']


module.exports = class Utils
  @bbCallback: (callback) -> return {success: ((model) -> callback(null, model)), error: ((model, err) -> callback(err or new Error("Backbone call failed")))}

  # @private
  @guid = -> return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4())

  # @private
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
  # @private
  @findOrGenerateReverseRelation: (relation) ->
    model_type = relation.model_type
    reverse_model_type = relation.reverse_model_type

    if relation.as
      reverse_relation = reverse_model_type.relation(relation.as)
#      throw new Error "Reverse relation from `#{@model_type.name}` as `#{@as}` not found on model `#{@reverse_model_type.name}`" unless @reverse_relation
      if reverse_relation
        reverse_relation.foreign_key = relation.foreign_key
        reverse_relation.reverse_relation = relation
    else
      # May have been set already if `as` was specified on the reverse relation
      reverse_relation = Utils.reverseRelation(reverse_model_type, model_type.model_name) # if @model_type.model_name

    # check for reverse since they need to store the foreign key
    if not reverse_relation and (relation.type is 'hasOne' or relation.type is 'hasMany')
      reverse_model_type.sync = model_type.createSync(reverse_model_type) unless _.isFunction(reverse_model_type.schema) # not a relational model
      reverse_relation =  reverse_model_type.schema().generateBelongsTo(reverse_model_type, model_type)
    return reverse_relation

  @reverseRelation: (model_type, owning_model_name) ->
    return null unless model_type.relation
    reverse_key = inflection.underscore(owning_model_name)
    return relation if relation = model_type.relation(reverse_key = inflection.underscore(owning_model_name)) # singular
    return model_type.relation(inflection.pluralize(reverse_key)) # plural

  # @private
  @dataId: (data) -> return data.id or data

  # @private
  @dataToModel: (data, model_type) ->
    return null unless data
    return (Utils.dataToModel(item) for item in data) if _.isArray(data)
    if data instanceof Backbone.Model
      model = data
    else if _.isObject(data)
      model = new model_type(model_type::parse(data))
    else
      model = new model_type({id: data})
      model._orm_needs_load = true
    return model

  @updateModel: (model, data) ->
    return if not data or (model is data) or data._orm_needs_load
    data = data.toJSON() if data instanceof Backbone.Model
    if _.isObject(data)
      model.set(data)
      delete model._orm_needs_load
    return model

  @updateOrNew: (data, model_type) ->
    if cache = model_type.cache()
      Utils.updateModel(model, data) if model = cache.get(Utils.dataId(data))
    unless model
      model = Utils.dataToModel(data, model_type)
      cache.set(model.id, model) if model and cache
    return model

  @joinTableURL: (relation) ->
    model_name1 = inflection.pluralize(inflection.underscore(relation.model_type.model_name))
    model_name2 = inflection.pluralize(inflection.underscore(relation.reverse_relation.model_type.model_name))
    return if model_name1.localeCompare(model_name2) < 0 then "#{model_name1}_#{model_name2}" else "#{model_name2}_#{model_name1}"

  @joinTableModelName: (relation) -> inflection.classify(inflection.singularize(Utils.joinTableURL(relation)))

  # @private
  @createJoinTableModel: (relation) ->
    schema = {}
    schema[relation.foreign_key] = ['Integer', indexed: true]
    schema[relation.reverse_relation.foreign_key] = ['Integer', indexed: true]

    try
      class JoinTable extends Backbone.Model
        urlRoot: "#{Utils.parseUrl(_.result(relation.model_type.prototype, 'url')).database_path}/#{Utils.joinTableURL(relation)}"
        @schema: schema
        sync: relation.model_type.createSync(JoinTable)
    catch
      class JoinTable extends Backbone.Model
        @model_name: Utils.joinTableModelName(relation)
        @schema: schema
        sync: relation.model_type.createSync(JoinTable)

    return JoinTable

  ##############################
  # Sorting
  ##############################
  # @private
  @isSorted: (models, fields) ->
    fields = _.uniq(fields)
    for model in models
      return false if last_model and @fieldCompare(last_model, model, fields) is 1
      last_model = model
    return true

  # @private
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

  # @private
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
  # Schema
  ##############################
  @resetSchemas: (model_types, options, callback) ->
    [options, callback] = [{}, options] if arguments.length is 2

    # ensure all models all initialized (reverse relationships may be initialized in a dependent model)
    model_type.schema() for model_type in model_types

    failed_schemas = []
    queue = new Queue(1)
    for model_type in model_types
      do (model_type) -> queue.defer (callback) -> model_type.resetSchema options, (err) ->
        if err
          failed_schemas.push(model_type.model_name)
          console.log "Error when dropping schema for #{model_type.model_name}. #{err}"
        callback()
    queue.await (err) ->
      console.log "#{model_types.length - failed_schemas.length} schemas dropped." if options.verbose
      return callback(new Error("Failed to migrate schemas: #{failed_schemas.join(', ')}")) if failed_schemas.length
      callback()

  ##############################
  # Batch
  ##############################
  # @private
  @batch: (model_type, query, options, callback, fn) ->
    Cursor = require './cursor'

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
  # @private
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
