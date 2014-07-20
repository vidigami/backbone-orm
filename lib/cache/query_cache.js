
/*
  backbone-orm.js 0.5.18
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var CLONE_DEPTH, JSONUtils, MemoryStore, QueryCache, Queue, inflection, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

_ = require('underscore');

inflection = require('inflection');

Queue = require('../queue');

JSONUtils = require('../json_utils');

MemoryStore = require('./memory_store');

CLONE_DEPTH = 2;

module.exports = QueryCache = (function() {
  function QueryCache() {
    this.storeKeyForModelTypes = __bind(this.storeKeyForModelTypes, this);
    this.getKeysForModelTypes = __bind(this.getKeysForModelTypes, this);
    this.clearMetaForModelTypes = __bind(this.clearMetaForModelTypes, this);
    this.clearModelTypes = __bind(this.clearModelTypes, this);
    this.reset = __bind(this.reset, this);
    this.hardReset = __bind(this.hardReset, this);
    this.getMeta = __bind(this.getMeta, this);
    this.getKey = __bind(this.getKey, this);
    this.get = __bind(this.get, this);
    this.set = __bind(this.set, this);
    this.configure = __bind(this.configure, this);
    this.enabled = false;
  }

  QueryCache.prototype.configure = function(options) {
    var CacheSingletons, _ref;
    if (options == null) {
      options = {};
    }
    this.enabled = !!options.enabled;
    this.verbose = !!options.verbose;
    this.hits = this.misses = this.clears = 0;
    this.store = options.store || new MemoryStore();
    CacheSingletons = require('../index').CacheSingletons;
    if ((_ref = CacheSingletons.ModelTypeID) != null) {
      _ref.configure({
        enabled: this.enabled,
        verbose: this.verbose
      });
    }
    return this;
  };

  QueryCache.prototype.cacheKey = function(model_type, query) {
    return "" + model_type.model_id + "_" + (JSON.stringify(query));
  };

  QueryCache.prototype.cacheKeyMeta = function(model_type) {
    return "meta_" + model_type.model_id;
  };

  QueryCache.prototype.set = function(model_type, query, related_model_types, value, callback) {
    var cache_key, m, model_types;
    if (!this.enabled) {
      return callback();
    }
    if (this.verbose) {
      console.log('QueryCache:set', model_type.model_name, (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = related_model_types.length; _i < _len; _i++) {
          m = related_model_types[_i];
          _results.push(m.model_name);
        }
        return _results;
      })(), this.cacheKey(model_type, query), JSON.stringify(value), '\n-----------');
    }
    model_types = [model_type].concat(related_model_types || []);
    cache_key = this.cacheKey(model_type, query);
    return this.store.set(cache_key, JSONUtils.deepClone(value, CLONE_DEPTH), (function(_this) {
      return function(err) {
        if (err) {
          return callback(err);
        }
        return _this.storeKeyForModelTypes(model_types, cache_key, callback);
      };
    })(this));
  };

  QueryCache.prototype.get = function(model_type, query, callback) {
    if (!this.enabled) {
      return callback();
    }
    return this.getKey(this.cacheKey(model_type, query), callback);
  };

  QueryCache.prototype.getKey = function(key, callback) {
    if (!this.enabled) {
      return callback();
    }
    return this.store.get(key, (function(_this) {
      return function(err, value) {
        if (err) {
          return callback(err);
        }
        if (_.isUndefined(value) || _.isNull(value)) {
          _this.misses++;
          if (_this.verbose) {
            console.log('QueryCache:miss', key, value, '\n-----------');
          }
          return callback();
        } else {
          _this.hits++;
          if (_this.verbose) {
            console.log('QueryCache:hit', key, value, '\n-----------');
          }
          return callback(null, JSONUtils.deepClone(value, CLONE_DEPTH));
        }
      };
    })(this));
  };

  QueryCache.prototype.getMeta = function(model_type, callback) {
    if (!this.enabled) {
      return callback();
    }
    return this.store.get(this.cacheKeyMeta(model_type), callback);
  };

  QueryCache.prototype.hardReset = function(callback) {
    if (!this.enabled) {
      return callback();
    }
    if (this.verbose) {
      console.log('QueryCache:hardReset');
    }
    this.hits = this.misses = this.clears = 0;
    if (this.store) {
      return this.store.reset(callback);
    }
    return callback();
  };

  QueryCache.prototype.reset = function(model_types, callback) {
    var model_type, related_model_types, _i, _len;
    if (arguments.length === 1) {
      return this.hardReset(model_types);
    }
    if (!this.enabled) {
      return callback();
    }
    if (!_.isArray(model_types)) {
      model_types = [model_types];
    }
    related_model_types = [];
    for (_i = 0, _len = model_types.length; _i < _len; _i++) {
      model_type = model_types[_i];
      related_model_types = related_model_types.concat(model_type.schema().allRelations());
    }
    model_types = model_types.concat(related_model_types);
    return this.clearModelTypes(model_types, callback);
  };

  QueryCache.prototype.clearModelTypes = function(model_types, callback) {
    if (!model_types.length) {
      return callback();
    }
    return this.getKeysForModelTypes(model_types, (function(_this) {
      return function(err, to_clear) {
        var key, queue, _fn, _i, _len, _ref;
        if (err) {
          return callback(err);
        }
        queue = new Queue();
        queue.defer(function(callback) {
          return _this.clearMetaForModelTypes(model_types, callback);
        });
        _ref = _.uniq(to_clear);
        _fn = function(key) {
          return queue.defer(function(callback) {
            if (_this.verbose) {
              console.log('QueryCache:cleared', key, '\n-----------');
            }
            _this.clears++;
            return _this.store.destroy(key, callback);
          });
        };
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          key = _ref[_i];
          _fn(key);
        }
        return queue.await(callback);
      };
    })(this));
  };

  QueryCache.prototype.clearMetaForModelTypes = function(model_types, callback) {
    var model_type, queue, _fn, _i, _len;
    queue = new Queue();
    _fn = (function(_this) {
      return function(model_type) {
        return queue.defer(function(callback) {
          if (_this.verbose) {
            console.log('QueryCache:meta cleared', model_type.model_name, '\n-----------');
          }
          return _this.store.destroy(_this.cacheKeyMeta(model_type), callback);
        });
      };
    })(this);
    for (_i = 0, _len = model_types.length; _i < _len; _i++) {
      model_type = model_types[_i];
      _fn(model_type);
    }
    return queue.await(callback);
  };

  QueryCache.prototype.getKeysForModelTypes = function(model_types, callback) {
    var all_keys, model_type, queue, _fn, _i, _len;
    all_keys = [];
    queue = new Queue(1);
    _fn = (function(_this) {
      return function(model_type) {
        return queue.defer(function(callback) {
          return _this.getMeta(model_type, function(err, keys) {
            if (err || !keys) {
              return callback(err);
            }
            all_keys = all_keys.concat(keys);
            return callback();
          });
        });
      };
    })(this);
    for (_i = 0, _len = model_types.length; _i < _len; _i++) {
      model_type = model_types[_i];
      _fn(model_type);
    }
    return queue.await(function(err) {
      return callback(err, all_keys);
    });
  };

  QueryCache.prototype.storeKeyForModelTypes = function(model_types, cache_key, callback) {
    var model_type, queue, _fn, _i, _len;
    queue = new Queue(1);
    _fn = (function(_this) {
      return function(model_type) {
        return queue.defer(function(callback) {
          var model_type_key;
          model_type_key = _this.cacheKeyMeta(model_type);
          return _this.store.get(model_type_key, function(err, keys) {
            if (err) {
              return callback(err);
            }
            (keys || (keys = [])).push(cache_key);
            return _this.store.set(model_type_key, _.uniq(keys), callback);
          });
        });
      };
    })(this);
    for (_i = 0, _len = model_types.length; _i < _len; _i++) {
      model_type = model_types[_i];
      _fn(model_type);
    }
    return queue.await(callback);
  };

  return QueryCache;

})();
