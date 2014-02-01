
/*
  backbone-orm.js 0.5.7
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
 */
var Backbone, MEMORY_STORE_KEYS, MemoryStore, ModelCache, Queue, _;

Backbone = require('backbone');

_ = require('underscore');

Queue = require('../queue');

MemoryStore = require('./memory_store');

MEMORY_STORE_KEYS = ['max', 'max_age', 'destroy'];

module.exports = ModelCache = (function() {
  function ModelCache() {
    this.enabled = false;
    this.caches = {};
    this.options = {
      modelTypes: {}
    };
    this.verbose = false;
  }

  ModelCache.prototype.configure = function(options) {
    var key, value, value_key, value_value, values, _base;
    if (options == null) {
      options = {};
    }
    this.enabled = options.enabled;
    this.reset(function() {});
    for (key in options) {
      value = options[key];
      if (_.isObject(value)) {
        (_base = this.options)[key] || (_base[key] = {});
        values = this.options[key];
        for (value_key in value) {
          value_value = value[value_key];
          values[value_key] = value_value;
        }
      } else {
        this.options[key] = value;
      }
    }
    return this;
  };

  ModelCache.prototype.configureSync = function(model_type, sync_fn) {
    var cache;
    if (model_type.prototype._orm_never_cache || !(cache = this.getOrCreateCache(model_type.model_name))) {
      return sync_fn;
    }
    model_type.cache = cache;
    return require('./sync')(model_type, sync_fn);
  };

  ModelCache.prototype.reset = function(callback) {
    var key, queue, value, _fn, _ref;
    queue = new Queue();
    _ref = this.caches;
    _fn = function(value) {
      return queue.defer(function(callback) {
        return value.reset(callback);
      });
    };
    for (key in _ref) {
      value = _ref[key];
      _fn(value);
    }
    return queue.await(callback);
  };

  ModelCache.prototype.hardReset = function() {
    var key, value, _ref;
    this.reset(function() {});
    _ref = this.caches;
    for (key in _ref) {
      value = _ref[key];
      delete this.caches[key];
    }
    return this;
  };

  ModelCache.prototype.getOrCreateCache = function(model_name) {
    var model_cache, options, _base;
    if (!this.enabled) {
      return null;
    }
    if (!model_name) {
      throw new Error("Missing model name for cache");
    }
    if (model_cache = this.caches[model_name]) {
      return model_cache;
    }
    if (options = this.options.modelTypes[model_name]) {
      return this.caches[model_name] = (typeof options.store === "function" ? options.store() : void 0) || new MemoryStore(_.pick(options, MEMORY_STORE_KEYS));
    } else if (this.options.store || this.options.max || this.options.max_age) {
      return this.caches[model_name] = (typeof (_base = this.options).store === "function" ? _base.store() : void 0) || new MemoryStore(_.pick(this.options, MEMORY_STORE_KEYS));
    }
    return null;
  };

  return ModelCache;

})();
