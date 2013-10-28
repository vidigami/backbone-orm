module.exports =

  license: """
    /*
      backbone-orm.js 0.0.1
      Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
      License: MIT (http://www.opensource.org/licenses/mit-license.php)
      Dependencies: Backbone.js and Underscore.js.
    */
    """

  start: """
(function() {
  /* local-only brunch-like require (based on https://github.com/brunch/commonjs-require-definition) */
  'use strict';

  var modules = {};
  var cache = {};

  var has = function(object, name) {
    return ({}).hasOwnProperty.call(object, name);
  };

  var expand = function(root, name) {
    var results = [], parts, part;
    if (/^\\.\\.?(\\/|$)/.test(name)) {
      parts = [root, name].join('/').split('/');
    } else {
      parts = name.split('/');
    }
    for (var i = 0, length = parts.length; i < length; i++) {
      part = parts[i];
      if (part === '..') {
        results.pop();
      } else if (part !== '.' && part !== '') {
        results.push(part);
      }
    }
    return results.join('/');
  };

  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    var _require = function(name) {
      var dir = dirname(path);
      var absolute = expand(dir, name);
      return require(absolute, path);
    };
    _require.register = require.register;
    return _require;
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    cache[name] = module;
    definition(module.exports, localRequire(name), module);
    return module.exports;
  };

  var require = function(name, loaderPath) {
    var path = expand(name, '.');
    if (loaderPath == null) loaderPath = '/';

    if (has(cache, path)) return cache[path].exports;
    if (has(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has(cache, dirIndex)) return cache[dirIndex].exports;
    if (has(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '" from '+ '"' + loaderPath + '"');
  };

  var define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    } else {
      modules[bundle] = fn;
    }
  };

  require.register = define;
    """

  end: """
  if (typeof exports == 'object') {
    module.exports = require('backbone-orm/lib/index');
  } else if (typeof define == 'function' && define.amd) {
    define('backbone-orm', ['underscore', 'backbone', 'moment', 'inflection'], function(){ return require('backbone-orm/lib/index'); });
  } else {
    var Backbone = this.Backbone;
    if (!Backbone && (typeof window.require == 'function')) {
      try { Backbone = window.require('backbone'); } catch (_error) { Backbone = this.Backbone = {}; }
    }
    Backbone.ORM = require('backbone-orm/lib/index');
  }
}).call(this);
    """
