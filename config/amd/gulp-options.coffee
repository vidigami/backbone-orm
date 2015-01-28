module.exports =
  karma: true,
  shims:
    underscore: {exports: '_'}
    backbone: {exports: 'Backbone', deps: ['underscore']}
    'backbone-orm': {exports: 'BackboneORM', deps: ['backbone', 'stream']}
    'parameters': {exports: '__test__parameters__', deps: ['backbone-orm']}
  post_load: 'window._ = window.Backbone = null; window.BackboneORM = backbone_orm;'
  aliases: {'lodash': 'underscore'}
