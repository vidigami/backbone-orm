
/*
  backbone-orm.js 0.5.12
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var Backbone, NodeUtils, Queue, Utils, fs, path, _;

fs = require('fs');

path = require('path');

_ = require('underscore');

Backbone = require('backbone');

Queue = require('../queue');

Utils = require('../utils');

module.exports = NodeUtils = (function() {
  function NodeUtils() {}

  NodeUtils.findModels = function(directory, options, callback) {
    var findModelsInDirectory, model_types;
    model_types = [];
    findModelsInDirectory = function(directory, options, callback) {
      return fs.readdir(directory, function(err, files) {
        var file, queue, _fn, _i, _len;
        if (err) {
          return callback(err);
        }
        if (!files) {
          return callback(null, model_types);
        }
        queue = new Queue(1);
        _fn = function(file) {
          return queue.defer(function(callback) {
            var pathed_file;
            pathed_file = path.join(directory, file);
            return fs.stat(pathed_file, function(err, stat) {
              var extension, model_path, model_type;
              if (err) {
                return callback(err);
              }
              if (stat.isDirectory()) {
                return findModelsInDirectory(pathed_file, options, callback);
              }
              extension = path.extname(pathed_file);
              if (!(extension === '.js' || extension === '.coffee')) {
                return callback();
              }
              try {
                model_path = path.join(directory, file);
                model_type = require(model_path);
                if (!(model_type && _.isFunction(model_type) && Utils.isModel(new model_type()) && model_type.resetSchema)) {
                  return callback();
                }
                if (options.append_path) {
                  model_type.path = model_path;
                }
                model_types.push(model_type);
                return callback();
              } catch (_error) {
                err = _error;
                if (options.verbose) {
                  console.log("findModels: skipping: " + err);
                }
                return callback();
              }
            });
          });
        };
        for (_i = 0, _len = files.length; _i < _len; _i++) {
          file = files[_i];
          _fn(file);
        }
        return queue.await(function(err) {
          if (err) {
            callback(err);
          }
          return callback(null, model_types);
        });
      });
    };
    return findModelsInDirectory(directory, options, callback);
  };

  NodeUtils.resetSchemasByDirectory = function(directory, options, callback) {
    var _ref;
    if (arguments.length === 2) {
      _ref = [{}, options], options = _ref[0], callback = _ref[1];
    }
    return NodeUtils.findModels(directory, options, function(err, model_types) {
      var model_type, queue, _fn, _i, _len;
      if (err) {
        return callback(err);
      }
      queue = new Queue(1);
      _fn = function(model_type) {
        return queue.defer(function(callback) {
          return model_type.resetSchema(options, callback);
        });
      };
      for (_i = 0, _len = model_types.length; _i < _len; _i++) {
        model_type = model_types[_i];
        _fn(model_type);
      }
      return queue.await(function(err) {
        if (err) {
          console.log("resetSchemasByDirectory: failed to reset schemas: " + err);
        }
        return callback(err);
      });
    });
  };

  return NodeUtils;

})();
