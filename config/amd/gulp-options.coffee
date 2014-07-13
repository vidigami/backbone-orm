module.exports =
  karma: true,
  shims:
    underscore: {exports: '_'}
    backbone: {exports: 'Backbone', deps: ['underscore']}
    'option_sets': {exports: '__option_sets__', deps: ['backbone-orm']}
    'parameters': {exports: '__test__parameters__', deps: ['backbone-orm']}
    'backbone-orm': {exports: 'BackboneORM', deps: ['backbone', 'moment', 'stream']}
  post_load: 'window._ = window.Backbone = window.moment = null; window.BackboneORM = backbone_orm;'
  aliases: {'lodash': 'underscore'}
