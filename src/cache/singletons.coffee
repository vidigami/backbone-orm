###
  backbone-orm.js 0.0.1
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js and Underscore.js.
###

module.exports =
  ModelCache: new (require('./model_cache'))()
  QueryCache: new (require('./query_cache'))()

try module.exports.ModelTypeID = new (require('../node/model_type_id'))() catch e
