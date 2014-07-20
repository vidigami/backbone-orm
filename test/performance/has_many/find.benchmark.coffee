Benchmark = require 'benchmark'

BackboneORM_Underscore = require '../builds/backbone-orm-underscore'
BackboneORM_Lodash = require '../builds/backbone-orm-lodash'

findInclude_Models = (BackboneORM, callback) ->
  generate {BackboneORM: BackboneORM, sync: BackboneORM.sync, count: 100}, (err, results) ->
    return callback(err) if err
    Owner = results.Owner

    Owner.cursor().include('reverses').toModels (err, models) ->
      callback(err) if err
      throw '' unless models.length is 100
      callback()

findInclude_JSON = (BackboneORM, callback) ->
  generate {BackboneORM: BackboneORM, sync: BackboneORM.sync, count: 100}, (err, results) ->
    return callback(err) if err
    Owner = results.Owner

    Owner.cursor().include('reverses').toJSON (err, models) ->
      callback(err) if err
      throw '' unless models.length is 100
      callback()

generate = require '../lib/generate_has_many'

module.exports =
  name: 'Timeout (asynchronous)'
  defer: true
  tests: [{
    name: 'findInclude_Models (underscore)'
    defer: true
    fn: (deferred) -> findInclude_Models BackboneORM_Underscore, (err) -> deferred.resolve()
  },{
    name: 'findInclude_Models (lodash)'
    defer: true
    fn: (deferred) -> findInclude_Models BackboneORM_Lodash, (err) -> deferred.resolve()
  },{
    name: 'findInclude_JSON (underscore)'
    defer: true
    fn: (deferred) -> findInclude_JSON BackboneORM_Underscore, (err) -> deferred.resolve()
  },{
    name: 'findInclude_JSON (lodash)'
    defer: true
    fn: (deferred) -> findInclude_JSON BackboneORM_Lodash, (err) -> deferred.resolve()
  }]
