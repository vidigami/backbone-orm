Benchmark = require 'benchmark'

BackboneORM_Underscore = require '../builds/backbone-orm-underscore'
BackboneORM_Lodash = require '../builds/backbone-orm-lodash'

runTests = (BackboneORM, callback) ->
  generate {BackboneORM: BackboneORM, sync: BackboneORM.sync, count: 100}, (err, results) ->
    return callback(err) if err
    Flat = results.Flat

    Flat.all (err, models) ->
      callback(err) if err
      throw '' unless models.length is 100
      callback()

generate = require '../lib/generate_has_one'

module.exports =
  name: 'Timeout (asynchronous)'
  defer: true
  tests: [{
    name: 'underscore'
    defer: true
    fn: (deferred) -> runTests BackboneORM_Underscore, (err) -> deferred.resolve()
  },{
    name: 'lodash'
    defer: true
    fn: (deferred) -> runTests BackboneORM_Lodash, (err) -> deferred.resolve()
  }]
