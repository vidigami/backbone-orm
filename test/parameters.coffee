((body) ->
  BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../backbone-orm')
  return body(BackboneORM) if BackboneORM or not define.amd
  require(['backbone-orm'], body)
) (BackboneORM) ->

  exports =
    sync: BackboneORM.sync
    # use parameter tags for postgres, mysql, etc.
    # $parameter_tags: '@memory_sync '

  (root = if window? then window else global).__test__parameters = exports; module?.exports = exports
  return exports
