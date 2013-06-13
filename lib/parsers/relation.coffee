util = require 'util'
_ = require 'underscore'
inflection = require 'inflection'

module.exports = class RelationParser
  @relation_types: ['hasOne', 'hasMany']

  @parse: (from_model, raw_relations) ->
    result = {}
    for name, relation_options of raw_relations
      relation_options = _.result(raw_relations, name)
      throw new Error "parseRelations, relation does not resolve to an array of [type, model, options]. Options: #{util.inspect(relation_options)}" if not _.isArray(relation_options)

      relation_type = relation_options[0]
      to_model = relation_options[1]
      options = _.reduce(relation_options.slice(2), ((k,v) -> _.extend(k, v)), {})

      result[name] =
        type: @_parseRelationType(relation_type)
        model: to_model
        foreign_key: options.foreign_key or inflection.foreign_key(name)
        # foreign_key: options.foreign_key or @_keyFromTypeAndModel(relation_type, from_model, to_model, options.reverse)
        options: options

    return result

  @_keyFromTypeAndModel: (relation_type, from_model, to_model, reverse) ->
    if relation_type is 'hasMany' # or (relation_type is 'hasOne' and reverse)
      return inflection.foreign_key(from_model._sync.model_name)
    else if relation_type is 'hasOne'
      return inflection.foreign_key(to_model._sync.model_name)
    else
      throw new Error "parseRelations, Unrecognized relation type: #{relation_type}"

  @_parseRelationType: (type) -> type