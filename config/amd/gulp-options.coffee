module.exports =
  karma: true,
  shims:
    underscore: {exports: '_'}
    backbone: {exports: 'Backbone', deps: ['underscore']}
    'backbone-orm': {exports: 'BackboneORM', deps: ['backbone', 'moment', 'stream']}
    'option_sets': {exports: '__option_sets__', deps: ['backbone-orm']}
    'parameters': {exports: '__test__parameters__', deps: ['backbone-orm']}
  post_load: 'window._ = window.Backbone = window.moment = null; window.BackboneORM = backbone_orm;'
  aliases: {'lodash': 'underscore'}
