
/*
  backbone-orm.js 0.5.10
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var Backbone, DESTROY_BATCH_LIMIT, JSONUtils, MemoryCursor, MemorySync, ModelCache, QueryCache, Queue, Schema, Utils, _;

_ = require('underscore');

Backbone = require('backbone');

Queue = require('../queue');

MemoryCursor = require('./cursor');

Schema = require('../schema');

Utils = require('../utils');

JSONUtils = require('../json_utils');

ModelCache = require('../cache/singletons').ModelCache;

QueryCache = require('../cache/singletons').QueryCache;

DESTROY_BATCH_LIMIT = 1000;

MemorySync = (function() {
  function MemorySync(model_type) {
    var _base;
    this.model_type = model_type;
    this.model_type.model_name = Utils.findOrGenerateModelName(this.model_type);
    this.schema = new Schema(this.model_type);
    this.store = (_base = this.model_type).store || (_base.store = {});
  }

  MemorySync.prototype.initialize = function() {
    if (this.is_initialized) {
      return;
    }
    this.is_initialized = true;
    return this.schema.initialize();
  };

  MemorySync.prototype.read = function(model, options) {
    var id, model_json;
    if (model.models) {
      return options.success((function() {
        var _ref, _results;
        _ref = this.store;
        _results = [];
        for (id in _ref) {
          model_json = _ref[id];
          _results.push(JSONUtils.deepClone(model_json));
        }
        return _results;
      }).call(this));
    } else {
      if (_.isUndefined(this.store[model.id])) {
        return options.error(new Error("Model not found with id: " + model.id));
      }
      return options.success(JSONUtils.deepClone(this.store[model.id]));
    }
  };

  MemorySync.prototype.create = function(model, options) {
    return QueryCache.reset(this.model_type, (function(_this) {
      return function(err) {
        var attributes, model_json;
        if (err) {
          return typeof options.error === "function" ? options.error(err) : void 0;
        }
        (attributes = {})[_this.model_type.prototype.idAttribute] = Utils.guid();
        model.set(attributes);
        model_json = _this.store[model.id] = model.toJSON();
        return options.success(JSONUtils.deepClone(model_json));
      };
    })(this));
  };

  MemorySync.prototype.update = function(model, options) {
    return QueryCache.reset(this.model_type, (function(_this) {
      return function(err) {
        var model_json;
        if (err) {
          return typeof options.error === "function" ? options.error(err) : void 0;
        }
        _this.store[model.id] = model_json = model.toJSON();
        return options.success(JSONUtils.deepClone(model_json));
      };
    })(this));
  };

  MemorySync.prototype["delete"] = function(model, options) {
    return QueryCache.reset(this.model_type, (function(_this) {
      return function(err) {
        if (err) {
          return typeof options.error === "function" ? options.error(err) : void 0;
        }
        if (!_this.store[model.id]) {
          return options.error(new Error('Model not found'));
        }
        delete _this.store[model.id];
        return options.success();
      };
    })(this));
  };

  MemorySync.prototype.resetSchema = function(options, callback) {
    return QueryCache.reset(this.model_type, (function(_this) {
      return function(err) {
        if (err) {
          return callback(err);
        }
        return _this.destroy({}, callback);
      };
    })(this));
  };

  MemorySync.prototype.cursor = function(query) {
    if (query == null) {
      query = {};
    }
    return new MemoryCursor(query, _.pick(this, ['model_type', 'store']));
  };

  MemorySync.prototype.destroy = function(query, callback) {
    return QueryCache.reset(this.model_type, (function(_this) {
      return function(err) {
        if (err) {
          return callback(err);
        }
        return _this.model_type.each(_.extend({
          $each: {
            limit: DESTROY_BATCH_LIMIT,
            json: true
          }
        }, query), (function(model_json, callback) {
          return Utils.patchRemoveByJSON(_this.model_type, model_json, function(err) {
            if (!err) {
              delete _this.store[model_json[_this.model_type.prototype.idAttribute]];
            }
            return callback(err);
          });
        }), callback);
      };
    })(this));
  };

  return MemorySync;

})();

module.exports = function(type) {
  var model_type, sync, sync_fn;
  if (Utils.isCollection(new type())) {
    model_type = Utils.configureCollectionModelType(type, module.exports);
    return type.prototype.sync = model_type.prototype.sync;
  }
  sync = new MemorySync(type);
  type.prototype.sync = sync_fn = function(method, model, options) {
    if (options == null) {
      options = {};
    }
    sync.initialize();
    if (method === 'createSync') {
      return module.exports.apply(null, Array.prototype.slice.call(arguments, 1));
    }
    if (method === 'sync') {
      return sync;
    }
    if (method === 'isRemote') {
      return false;
    }
    if (method === 'schema') {
      return sync.schema;
    }
    if (method === 'tableName') {
      return void 0;
    }
    if (sync[method]) {
      return sync[method].apply(sync, Array.prototype.slice.call(arguments, 1));
    } else {
      return void 0;
    }
  };
  Utils.configureModelType(type);
  return ModelCache.configureSync(type, sync_fn);
};
