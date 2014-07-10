try BackboneORM = require 'backbone-orm' catch err then BackboneORM = require('../../backbone-orm')

exports =
  sync: BackboneORM.sync

(if window? then window else if global? then global).test_parameters = exports; module?.exports = exports
