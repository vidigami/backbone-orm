_ = require 'underscore'
BackboneORM = require '../core'

ALL_CONVENTIONS =
  default: require '../conventions/underscore'
  underscore: require '../conventions/underscore'
  camelize: require '../conventions/camelize'
  classify: require '../conventions/classify'

# set up defaults
BackboneORM.naming_conventions = ALL_CONVENTIONS.default
BackboneORM.model_cache = new (require '../cache/model_cache')()

module.exports = (options={}) ->
  for key, value of options
    switch key
      when 'model_cache'
        BackboneORM.model_cache.configure(options.model_cache)

      when 'naming_conventions'
        # set by name
        if _.isString(value)
          (BackboneORM.naming_conventions = convention; continue) if convention = ALL_CONVENTIONS[value]
          console.log "BackboneORM configure: could not find naming_conventions: #{value}. Available: #{_.keys(ALL_CONVENTIONS).join(', ')}"

        # set by functions
        else
          BackboneORM.naming_conventions = value

      else
        BackboneORM[key] = value

