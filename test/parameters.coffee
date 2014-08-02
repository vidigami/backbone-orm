BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../backbone-orm')

exports =
  sync: BackboneORM.sync
  # schema: # TODO: add parameter sets for String and Integer
  #   id: ['String']
  # use parameter tags for postgres, mysql, etc.
  # $parameter_tags: '@memory_sync '

(root = if window? then window else global).__test__parameters = exports; module?.exports = exports
