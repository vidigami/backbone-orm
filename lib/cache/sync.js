
/*
  backbone-orm.js 0.5.14
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var CacheCursor, CacheSync, DESTROY_BATCH_LIMIT, DESTROY_THREADS, Schema, Utils, bbCallback, _;

_ = require('underscore');

CacheCursor = require('./cursor');

Schema = require('../schema');

Utils = require('../utils');

bbCallback = Utils.bbCallback;

DESTROY_BATCH_LIMIT = 1000;

DESTROY_THREADS = 100;

CacheSync = (function() {
  function CacheSync(model_type, wrapped_sync_fn) {
    this.model_type = model_type;
    this.wrapped_sync_fn = wrapped_sync_fn;
  }

  CacheSync.prototype.initialize = function() {
    if (this.is_initialized) {
      return;
    }
    this.is_initialized = true;
    this.wrapped_sync_fn('initialize');
    if (!this.model_type.model_name) {
      throw new Error('Missing model_name for model');
    }
  };

  CacheSync.prototype.read = function(model, options) {
    var cached_model;
    if (!options.force && (cached_model = this.model_type.cache.get(model.id))) {
      return options.success(cached_model.toJSON());
    }
    return this.wrapped_sync_fn('read', model, options);
  };

  CacheSync.prototype.create = function(model, options) {
    return this.wrapped_sync_fn('create', model, bbCallback((function(_this) {
      return function(err, json) {
        var attributes, cache_model;
        if (err) {
          return options.error(err);
        }
        (attributes = {})[_this.model_type.prototype.idAttribute] = json[_this.model_type.prototype.idAttribute];
        model.set(attributes);
        if (cache_model = _this.model_type.cache.get(model.id)) {
          if (cache_model !== model) {
            Utils.updateModel(cache_model, model);
          }
        } else {
          _this.model_type.cache.set(model.id, model);
        }
        return options.success(json);
      };
    })(this)));
  };

  CacheSync.prototype.update = function(model, options) {
    return this.wrapped_sync_fn('update', model, bbCallback((function(_this) {
      return function(err, json) {
        var cache_model;
        if (err) {
          return options.error(err);
        }
        if (cache_model = _this.model_type.cache.get(model.id)) {
          if (cache_model !== model) {
            Utils.updateModel(cache_model, model);
          }
        } else {
          _this.model_type.cache.set(model.id, model);
        }
        return options.success(json);
      };
    })(this)));
  };

  CacheSync.prototype["delete"] = function(model, options) {
    this.model_type.cache.destroy(model.id);
    return this.wrapped_sync_fn('delete', model, bbCallback((function(_this) {
      return function(err, json) {
        if (err) {
          return options.error(err);
        }
        return options.success(json);
      };
    })(this)));
  };

  CacheSync.prototype.resetSchema = function(options, callback) {
    return this.model_type.cache.reset((function(_this) {
      return function(err) {
        if (err) {
          return callback(err);
        }
        return _this.wrapped_sync_fn('resetSchema', options, callback);
      };
    })(this));
  };

  CacheSync.prototype.cursor = function(query) {
    if (query == null) {
      query = {};
    }
    return new CacheCursor(query, _.pick(this, ['model_type', 'wrapped_sync_fn']));
  };

  CacheSync.prototype.destroy = function(query, callback) {
    return this.model_type.each(_.extend({
      $each: {
        limit: DESTROY_BATCH_LIMIT,
        threads: DESTROY_THREADS
      }
    }, query), ((function(_this) {
      return function(model, callback) {
        return model.destroy(callback);
      };
    })(this)), callback);
  };

  CacheSync.prototype.connect = function(url) {
    this.model_type.cache.reset();
    return this.wrapped_sync_fn('connect');
  };

  return CacheSync;

})();

module.exports = function(model_type, wrapped_sync_fn) {
  var sync, sync_fn;
  sync = new CacheSync(model_type, wrapped_sync_fn);
  model_type.prototype.sync = sync_fn = function(method, model, options) {
    if (options == null) {
      options = {};
    }
    sync.initialize();
    if (method === 'createSync') {
      return wrapped_sync_fn.apply(null, arguments);
    }
    if (method === 'sync') {
      return sync;
    }
    if (sync[method]) {
      return sync[method].apply(sync, Array.prototype.slice.call(arguments, 1));
    }
    return wrapped_sync_fn.apply(wrapped_sync_fn, Array.prototype.slice.call(arguments));
  };
  return sync_fn;
};
