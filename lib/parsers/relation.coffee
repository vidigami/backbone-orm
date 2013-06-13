_ = require 'underscore'
inflection = require 'inflection'

module.exports = class RelationParser
  @relation_types: ['hasOne', 'hasMany']

  @parse: (from_model, raw_relations) ->
    result = {}
    for name, relation_options of raw_relations
      relation_options = _.result(raw_relations, name)
      return (console.log 'Error: parseRelations, relation does not resolve to an array of [type, model, options]', relation_options) if not _.isArray(relation_options)

      relation_type = relation_options[0]
      to_model = relation_options[1]
      console.log relation_options
      options = _.reduce(relation_options.slice(2), ((k,v) -> _.extend(k, v)), {})

      result[name] = @createParsedRelation(name, relation_type, from_model, to_model, options)

    return result

  @createParsedRelation: (name,  relation_type, from_model, to_model, options) ->
    type: @_parseRelationType(relation_type)
    model: to_model
    foreign_key: options.foreign_key or @_keyFromTypeAndModel(relation_type, from_model, to_model, options.reverse)
    options: options

  @_keyFromTypeAndModel: (relation_type, from_model, to_model, reverse) ->
    if relation_type is 'hasMany' or (relation_type is 'hasOne' and reverse)
      return inflection.foreign_key(from_model._sync.model_name)
    if relation_type is 'hasOne'
      return inflection.foreign_key(to_model._sync.model_name)

  @_parseRelationType: (type) -> type