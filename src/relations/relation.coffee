###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
Backbone = require 'backbone'

BackboneORM = require '../core'
Queue = require '../lib/queue'
Utils = require '../lib/utils'

# @nodoc
module.exports = class Relation
  # hasJoinTable: -> return !!@join_table or (@reverse_relation and !!@reverse_relation.join_table)
  # isManyToMany: -> return @type is 'hasMany' and @reverse_relation and @reverse_relation.type is 'hasMany'
  isEmbedded: -> return !!(@embed or (@reverse_relation and @reverse_relation.embed))
  isVirtual: -> return !!(@virtual or (@reverse_relation and @reverse_relation.virtual))

  findOrGenerateJoinTable: ->
    # already exists
    return join_table if join_table = (@join_table or @reverse_relation.join_table)
    return @model_type.schema().generateJoinTable(@)

  _findOrGenerateReverseRelation: ->
    model_type = @model_type
    reverse_model_type = @reverse_model_type
    reverse_model_type.sync = model_type.createSync(reverse_model_type) unless _.isFunction(reverse_model_type.schema) # convert to relational

    reverse_relation = reverse_model_type.relation(@as)
    reverse_relation = reverse_model_type.relation(BackboneORM.naming_conventions.attribute(model_type.model_name, false)) unless reverse_relation # singular
    reverse_relation = reverse_model_type.relation(BackboneORM.naming_conventions.attribute(model_type.model_name, true)) unless reverse_relation # plural

    if not reverse_relation and (@type isnt 'belongsTo')
      reverse_relation = reverse_model_type.schema().generateBelongsTo(model_type)

    reverse_relation.reverse_relation = @ if reverse_relation and not reverse_relation.reverse_relation
    return reverse_relation

  _saveRelated: (model, related_models, callback) ->
    return callback() if @embed or not @reverse_relation or (@type is 'belongsTo') # no foriegn key, no save required
    return callback() if @isVirtual() # skip virtual attributes

    @cursor(model, @key).toJSON (err, json) =>
      return callback(err) if err

      json = (if json then [json] else []) unless _.isArray(json) # a One relation
      queue = new Queue(1)

      related_ids = _.pluck(related_models, 'id')
      changes = _.groupBy(json, (test) => if _.contains(related_ids, test.id) then 'kept' else 'removed')
      added_ids = if changes.kept then _.difference(related_ids, (test.id for test in changes.kept)) else related_ids

      # destroy removed
      if changes.removed
        if @join_table
          queue.defer (callback) =>
            query = {}
            query[@join_key] = model.id
            query[@reverse_relation.join_key] = {$in: (related_json[@reverse_model_type::idAttribute] for related_json in changes.removed)}
            @join_table.destroy query, callback
        else
          queue.defer (callback) =>
            Utils.each changes.removed, ((related_json, callback) =>
              related_json[@reverse_relation.foreign_key] = null
              Utils.modelJSONSave(related_json, @reverse_model_type, callback)
            ), callback

      # create new
      if added_ids.length
        if @join_table
          queue.defer (callback) =>
            Utils.each added_ids, ((related_id, callback) =>
              attributes = {}
              attributes[@foreign_key] = model.id
              attributes[@reverse_relation.foreign_key] = related_id
              # console.log "Creating join for: #{@model_type.model_name} join: #{JSONUtils.stringify(attributes)}"
              join = new @join_table(attributes)
              join.save callback
            ), callback

        else
          # add new, if they have changed
          queue.defer (callback) =>
            Utils.each added_ids, ((added_id, callback) =>
              related_model = _.find(related_models, (test) -> test.id is added_id)

              return callback() unless @reverse_relation._hasChanged(related_model) # related has not changed
              related_model.save (err, saved_model) =>
                cache.set(saved_model.id, saved_model) if not err and cache = @reverse_model_type.cache
                callback(err)
            ), callback

      queue.await callback
