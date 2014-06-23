###
  backbone-orm.js 0.5.16
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

module.exports =
  ModelCache: new (require('./model_cache'))()
  QueryCache: new (require('./query_cache'))()

try module.exports.ModelTypeID = new (require('../node/model_type_id'))() catch e
