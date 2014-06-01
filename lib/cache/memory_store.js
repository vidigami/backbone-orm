
/*
  backbone-orm.js 0.5.15
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var LRU, MemoryStore, inflection, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

_ = require('underscore');

LRU = require('lru-cache');

inflection = require('inflection');

module.exports = MemoryStore = (function() {
  function MemoryStore(options) {
    var key, normalized_options, value;
    if (options == null) {
      options = {};
    }
    this.forEach = __bind(this.forEach, this);
    this.reset = __bind(this.reset, this);
    this.destroy = __bind(this.destroy, this);
    this.get = __bind(this.get, this);
    this.set = __bind(this.set, this);
    normalized_options = {};
    for (key in options) {
      value = options[key];
      if (key === 'destroy') {
        normalized_options.dispose = value;
      } else {
        normalized_options[this._normalizeKey(key)] = value;
      }
    }
    this.cache = new LRU(normalized_options);
  }

  MemoryStore.prototype.set = function(key, value, callback) {
    if (value._orm_never_cache) {
      return (typeof callback === "function" ? callback(null, value) : void 0) || this;
    }
    this.cache.set(key, value);
    if (typeof callback === "function") {
      callback(null, value);
    }
    return this;
  };

  MemoryStore.prototype.get = function(key, callback) {
    var value;
    value = this.cache.get(key);
    if (typeof callback === "function") {
      callback(null, value);
    }
    return value;
  };

  MemoryStore.prototype.destroy = function(key, callback) {
    this.cache.del(key);
    if (typeof callback === "function") {
      callback();
    }
    return this;
  };

  MemoryStore.prototype.reset = function(callback) {
    this.cache.reset();
    if (typeof callback === "function") {
      callback();
    }
    return this;
  };

  MemoryStore.prototype._normalizeKey = function(key) {
    key = inflection.underscore(key);
    if (key.indexOf('_') < 0) {
      return key.toLowerCase();
    }
    return inflection.camelize(key);
  };

  MemoryStore.prototype.forEach = function(callback) {
    return this.cache.forEach(callback);
  };

  return MemoryStore;

})();
