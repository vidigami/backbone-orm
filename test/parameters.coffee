BackboneORM = window?.BackboneORM or require?('backbone-orm')

exports =
  sync: BackboneORM.sync
  # use parameter tags for postgres, mysql, etc.
  # $parameter_tags: '@memory_sync '

(if window? then window else if global? then global).__test__parameters = exports; module?.exports = exports
