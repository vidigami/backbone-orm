util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'
Queue = require 'queue-async'
inflection = require 'inflection'

Utils = require '../utils'
bbCallback = Utils.bbCallback

module.exports = class Relation
  # hasJoinTable: -> return !!@join_table or (@reverse_relation and !!@reverse_relation.join_table)
  # isManyToMany: -> return @type is 'hasMany' and @reverse_relation and @reverse_relation.type is 'hasMany'
  isVirtual: -> return !!@virtual or (@reverse_relation and @reverse_relation.virtual)

  findOrGenerateJoinTable: ->
    # already exists
    return join_table if join_table = (@join_table or @reverse_relation.join_table)
    return @model_type.schema().generateJoinTable(@)

  _findOrGenerateReverseRelation: ->
    model_type = @model_type
    reverse_model_type = @reverse_model_type
    reverse_model_type.sync = model_type.createSync(reverse_model_type) unless _.isFunction(reverse_model_type.schema) # convert to relational

    key_root = @as or inflection.underscore(model_type.model_name)
    reverse_relation = reverse_model_type.relation(key_root) # as
    reverse_relation = reverse_model_type.relation(inflection.singularize(key_root)) unless reverse_relation # singular
    reverse_relation = reverse_model_type.relation(inflection.pluralize(key_root)) unless reverse_relation # plural

    if not reverse_relation and (@type isnt 'belongsTo')
      reverse_relation = reverse_model_type.schema().generateBelongsTo(model_type)

    reverse_relation.reverse_relation = @ if reverse_relation and not reverse_relation.reverse_relation
    return reverse_relation

  _saveRelated: (model, related_models, callback) ->
    return callback() if @embed or not @reverse_relation or (@reverse_relation.type is 'hasOne') # no foriegn key, no save required
    return callback() if @isVirtual() # skip virtual attributes

    @cursor(model, @key).toJSON (err, json) =>
      return callback(err) if err

      json = (if json then [json] else []) unless _.isArray(json) # a One relation
      queue = new Queue(1)

      use_join = @join_table # and not @reverse_model_type::sync('isRemote') # TODO: optimize relationship update
      related_ids = _.pluck(related_models, 'id')
      changes = _.groupBy(json, (test) => if _.contains(related_ids, test.id) then 'kept' else 'removed')
      added_ids = if changes.kept then _.difference(related_ids, (test.id for test in changes.kept)) else related_ids

      # update store through join table
      if use_join
        # destroy removed
        if changes.removed
          queue.defer (callback) =>
            destroy_query = {}
            destroy_query[@reverse_relation.join_key] = {$in: (model_json.id for model_json in changes.removed)}
            @join_table.destroy destroy_query, callback

        # create new - TODO: optimize through batch create
        for related_id in added_ids
          do (related_id) => queue.defer (callback) =>
            attributes = {}
            attributes[@foreign_key] = model.id
            attributes[@reverse_relation.foreign_key] = related_id
            # console.log "Creating join for: #{@model_type.model_name} join: #{util.inspect(attributes)}"
            join = new @join_table(attributes)
            join.save {}, Utils.bbCallback callback

      # clear back links on models and save
      else
        # clear removed - TODO: optimize using batch update
        if changes.removed
          for related_json in changes.removed
            do (related_json) => queue.defer (callback) =>
              @_clearAndSaveRelatedBacklink(model, related_json, callback)

        # add new, if they have changed
        for added_id in added_ids
          related_model = _.find(related_models, (test) -> test.id is added_id)
          continue if not @reverse_relation._hasChanged(related_model) # related has not changed

          do (related_model) => queue.defer (callback) =>
            related_model.save {}, Utils.bbCallback (err, saved_model) =>
              cache.set(saved_model.id, saved_model) if not err and cache = @reverse_model_type.cache
              callback(err)

      queue.await callback

  # NOTE: this method takes raw data and instantiates a simple model for a non-relational data write
  _clearAndSaveRelatedBacklink: (model, related_json, callback) ->
    return callback() unless (@reverse_relation and @reverse_relation.type is 'belongsTo')

    # no longer a match
    return callback() unless related_json[@reverse_relation.foreign_key] is model.id

    # update the foreign key and save raw data
    related_json[@reverse_relation.foreign_key] = null
    related_model = new Backbone.Model(related_json)
    @reverse_model_type::sync 'update', related_model, bbCallback callback
