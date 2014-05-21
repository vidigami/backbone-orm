
/*
  backbone-orm.js 0.5.14
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var Backbone, DatabaseURL, ModelStream, Queue, Utils, modelEach, modelInterval, moment, _;

_ = require('underscore');

Backbone = require('backbone');

moment = require('moment');

Queue = require('../queue');

Utils = require('../utils');

ModelStream = require('./model_stream');

modelEach = require('./model_each');

modelInterval = require('./model_interval');

DatabaseURL = require('../database_url');

require('./collection');

module.exports = function(model_type) {
  var BackboneModelExtensions, fn, key, overrides, _findOrClone, _results;
  BackboneModelExtensions = (function() {
    function BackboneModelExtensions() {}

    return BackboneModelExtensions;

  })();
  model_type.createSync = function(target_model_type) {
    return model_type.prototype.sync('createSync', target_model_type);
  };
  model_type.resetSchema = function(options, callback) {
    var _ref;
    if (arguments.length === 1) {
      _ref = [{}, options], options = _ref[0], callback = _ref[1];
    }
    return model_type.prototype.sync('resetSchema', options, callback);
  };
  model_type.cursor = function(query) {
    if (query == null) {
      query = {};
    }
    return model_type.prototype.sync('cursor', query);
  };
  model_type.destroy = function(query, callback) {
    var _ref;
    if (arguments.length === 1) {
      _ref = [{}, query], query = _ref[0], callback = _ref[1];
    }
    if (!_.isObject(query)) {
      query = {
        id: query
      };
    }
    return model_type.prototype.sync('destroy', query, callback);
  };
  model_type.db = function() {
    return model_type.prototype.sync('db');
  };
  model_type.exists = function(query, callback) {
    var _ref;
    if (arguments.length === 1) {
      _ref = [{}, query], query = _ref[0], callback = _ref[1];
    }
    return model_type.prototype.sync('cursor', query).exists(callback);
  };
  model_type.count = function(query, callback) {
    var _ref;
    if (arguments.length === 1) {
      _ref = [{}, query], query = _ref[0], callback = _ref[1];
    }
    return model_type.prototype.sync('cursor', query).count(callback);
  };
  model_type.all = function(callback) {
    return model_type.prototype.sync('cursor', {}).toModels(callback);
  };
  model_type.find = function(query, callback) {
    var _ref;
    if (arguments.length === 1) {
      _ref = [{}, query], query = _ref[0], callback = _ref[1];
    }
    return model_type.prototype.sync('cursor', query).toModels(callback);
  };
  model_type.findOne = function(query, callback) {
    var _ref;
    if (arguments.length === 1) {
      _ref = [{}, query], query = _ref[0], callback = _ref[1];
    }
    query = _.isObject(query) ? _.extend({
      $one: true
    }, query) : {
      id: query,
      $one: true
    };
    return model_type.prototype.sync('cursor', query).toModels(callback);
  };
  model_type.findOrCreate = function(data, callback) {
    var query;
    if (!_.isObject(data) || Utils.isModel(data) || Utils.isCollection(data)) {
      throw 'findOrCreate requires object data';
    }
    query = _.extend({
      $one: true
    }, data);
    return model_type.prototype.sync('cursor', query).toModels(function(err, model) {
      if (err) {
        return callback(err);
      }
      if (model) {
        return callback(null, model);
      }
      return (new model_type(data)).save(callback);
    });
  };
  model_type.findOneNearestDate = function(date, options, query, callback) {
    var functions, key, _ref, _ref1;
    if (!(key = options.key)) {
      throw new Error("Missing options key");
    }
    if (arguments.length === 2) {
      _ref = [{}, query], query = _ref[0], callback = _ref[1];
    } else if (arguments.length === 3) {
      _ref1 = [moment.utc().toDate(), {}, query], options = _ref1[0], query = _ref1[1], callback = _ref1[2];
    } else {
      query = _.clone(query);
    }
    query.$one = true;
    functions = [
      ((function(_this) {
        return function(callback) {
          query[key] = {
            $lte: date
          };
          return model_type.cursor(query).sort("-" + key).toModels(callback);
        };
      })(this)), ((function(_this) {
        return function(callback) {
          query[key] = {
            $gte: date
          };
          return model_type.cursor(query).sort(key).toModels(callback);
        };
      })(this))
    ];
    if (options.reverse) {
      functions = [functions[1], functions[0]];
    }
    return functions[0](function(err, model) {
      if (err) {
        return callback(err);
      }
      if (model) {
        return callback(null, model);
      }
      return functions[1](callback);
    });
  };
  model_type.each = function(query, iterator, callback) {
    var _ref;
    if (arguments.length === 2) {
      _ref = [{}, query, iterator], query = _ref[0], iterator = _ref[1], callback = _ref[2];
    }
    return modelEach(model_type, query, iterator, callback);
  };
  model_type.eachC = function(query, callback, iterator) {
    var _ref;
    if (arguments.length === 2) {
      _ref = [{}, query, callback], query = _ref[0], callback = _ref[1], iterator = _ref[2];
    }
    return modelEach(model_type, query, iterator, callback);
  };
  model_type.stream = function(query) {
    if (query == null) {
      query = {};
    }
    if (!ModelStream) {
      throw new Error('Stream is a large dependency so you need to manually include "stream.js" in the browser.');
    }
    return new ModelStream(model_type, query);
  };
  model_type.interval = function(query, iterator, callback) {
    return modelInterval(model_type, query, iterator, callback);
  };
  model_type.intervalC = function(query, callback, iterator) {
    return modelInterval(model_type, query, iterator, callback);
  };
  model_type.prototype.modelName = function() {
    return model_type.model_name;
  };
  model_type.prototype.cache = function() {
    return model_type.cache;
  };
  model_type.prototype.schema = model_type.schema = function() {
    return model_type.prototype.sync('schema');
  };
  model_type.prototype.tableName = model_type.tableName = function() {
    return model_type.prototype.sync('tableName');
  };
  model_type.prototype.relation = model_type.relation = function(key) {
    var schema;
    if (schema = model_type.prototype.sync('schema')) {
      return schema.relation(key);
    } else {
      return void 0;
    }
  };
  model_type.prototype.relationIsEmbedded = model_type.relationIsEmbedded = function(key) {
    var relation;
    if (relation = model_type.relation(key)) {
      return !!relation.embed;
    } else {
      return false;
    }
  };
  model_type.prototype.reverseRelation = model_type.reverseRelation = function(key) {
    var schema;
    if (schema = model_type.prototype.sync('schema')) {
      return schema.reverseRelation(key);
    } else {
      return void 0;
    }
  };
  model_type.prototype.isLoaded = function(key) {
    if (arguments.length === 0) {
      key = '__model__';
    }
    return !Utils.orSet(this, 'needs_load', {})[key];
  };
  model_type.prototype.setLoaded = function(key, is_loaded) {
    var needs_load, _ref;
    if (arguments.length === 1) {
      _ref = ['__model__', key], key = _ref[0], is_loaded = _ref[1];
    }
    needs_load = Utils.orSet(this, 'needs_load', {});
    if (is_loaded && Utils.get(this, 'is_initialized')) {
      delete needs_load[key];
      return;
    }
    return needs_load[key] = !is_loaded;
  };
  model_type.prototype.isLoadedExists = function(key) {
    if (arguments.length === 0) {
      key = '__model__';
    }
    return Utils.orSet(this, 'needs_load', {}).hasOwnProperty(key);
  };
  model_type.prototype.isPartial = function() {
    return !!Utils.get(this, 'partial');
  };
  model_type.prototype.setPartial = function(is_partial) {
    if (is_partial) {
      return Utils.set(this, 'partial', true);
    } else {
      return Utils.unset(this, 'partial');
    }
  };
  model_type.prototype.addUnset = function(key) {
    var unsets;
    unsets = Utils.orSet(this, 'unsets', []);
    if (unsets.indexOf(key) < 0) {
      return unsets.push(key);
    }
  };
  model_type.prototype.removeUnset = function(key) {
    var index, unsets;
    if (!(unsets = Utils.get(this, 'unsets', null))) {
      return;
    }
    if ((index = unsets.indexOf(key)) >= 0) {
      return unsets.splice(index, 1);
    }
  };
  model_type.prototype.fetchRelated = function(relations, callback) {
    var queue, _ref;
    if (arguments.length === 1) {
      _ref = [null, relations], relations = _ref[0], callback = _ref[1];
    }
    queue = new Queue(1);
    queue.defer((function(_this) {
      return function(callback) {
        if (_this.isLoaded()) {
          return callback();
        }
        return _this.fetch(callback);
      };
    })(this));
    queue.defer((function(_this) {
      return function(callback) {
        var key, keys, relations_queue, _fn, _i, _len;
        keys = _.keys(Utils.orSet(_this, 'needs_load', {}));
        if (relations && !_.isArray(relations)) {
          relations = [relations];
        }
        if (_.isArray(relations)) {
          keys = _.intersection(keys, relations);
        }
        relations_queue = new Queue();
        _fn = function(key) {
          return relations_queue.defer(function(callback) {
            return _this.get(key, callback);
          });
        };
        for (_i = 0, _len = keys.length; _i < _len; _i++) {
          key = keys[_i];
          _fn(key);
        }
        return relations_queue.await(callback);
      };
    })(this));
    return queue.await(callback);
  };
  model_type.prototype.patchAdd = function(key, relateds, callback) {
    var relation;
    if (!(relation = this.relation(key))) {
      return callback(new Error("patchAdd: relation '" + key + "' unrecognized"));
    }
    if (!relateds) {
      return callback(new Error("patchAdd: missing relateds for '" + key + "'"));
    }
    return relation.patchAdd(this, relateds, callback);
  };
  model_type.prototype.patchRemove = function(key, relateds, callback) {
    var queue, relation, schema, _fn, _ref;
    if (arguments.length === 1) {
      callback = key;
      schema = model_type.schema();
      queue = new Queue(1);
      _ref = schema.relations;
      _fn = (function(_this) {
        return function(relation) {
          return queue.defer(function(callback) {
            return relation.patchRemove(_this, callback);
          });
        };
      })(this);
      for (key in _ref) {
        relation = _ref[key];
        _fn(relation);
      }
      return queue.await(callback);
    } else {
      if (!(relation = this.relation(key))) {
        return callback(new Error("patchRemove: relation '" + key + "' unrecognized"));
      }
      if (arguments.length === 2) {
        callback = relateds;
        return relation.patchRemove(this, callback);
      } else {
        if (!relateds) {
          return callback(new Error("patchRemove: missing relateds for '" + key + "'"));
        }
        return relation.patchRemove(this, relateds, callback);
      }
    }
  };
  model_type.prototype.cursor = function(key, query) {
    var relation, schema;
    if (query == null) {
      query = {};
    }
    if (model_type.schema) {
      schema = model_type.schema();
    }
    if (schema && (relation = schema.relation(key))) {
      return relation.cursor(this, key, query);
    } else {
      throw new Error("" + schema.model_name + "::cursor: Unexpected key: " + key + " is not a relation");
    }
  };
  _findOrClone = function(model, options) {
    var cache, clone, _base, _name;
    if (model.isNew() || !model.modelName) {
      return model.clone(options);
    }
    cache = (_base = options._cache)[_name = model.modelName()] || (_base[_name] = {});
    if (!(clone = cache[model.id])) {
      clone = cache[model.id] = model.clone(options);
    }
    return clone;
  };
  overrides = {
    initialize: function(attributes) {
      var key, needs_load, relation, schema, value, _ref;
      if (model_type.schema && (schema = model_type.schema())) {
        _ref = schema.relations;
        for (key in _ref) {
          relation = _ref[key];
          relation.initializeModel(this);
        }
        needs_load = Utils.orSet(this, 'needs_load', {});
        for (key in needs_load) {
          value = needs_load[key];
          if (!value) {
            delete needs_load[key];
          }
        }
        Utils.set(this, 'is_initialized', true);
      }
      return model_type.prototype._orm_original_fns.initialize.apply(this, arguments);
    },
    fetch: function(options) {
      var callback;
      if (_.isFunction(callback = arguments[arguments.length - 1])) {
        switch (arguments.length) {
          case 1:
            options = Utils.wrapOptions({}, callback);
            break;
          case 2:
            options = Utils.wrapOptions(options, callback);
        }
      } else {
        options || (options = {});
      }
      return model_type.prototype._orm_original_fns.fetch.call(this, Utils.wrapOptions(options, (function(_this) {
        return function(err, model, resp, options) {
          if (err) {
            return typeof options.error === "function" ? options.error(_this, resp, options) : void 0;
          }
          _this.setLoaded(true);
          return typeof options.success === "function" ? options.success(_this, resp, options) : void 0;
        };
      })(this)));
    },
    unset: function(key) {
      var id;
      this.addUnset(key);
      id = this.id;
      model_type.prototype._orm_original_fns.unset.apply(this, arguments);
      if (key === 'id' && model_type.cache && id && (model_type.cache.get(id) === this)) {
        return model_type.cache.destroy(id);
      }
    },
    set: function(key, value, options) {
      var attributes, relation, relational_attributes, schema, simple_attributes;
      if (!(model_type.schema && (schema = model_type.schema()))) {
        return model_type.prototype._orm_original_fns.set.apply(this, arguments);
      }
      if (_.isString(key)) {
        (attributes = {})[key] = value;
      } else {
        attributes = key;
        options = value;
      }
      simple_attributes = {};
      relational_attributes = {};
      for (key in attributes) {
        value = attributes[key];
        if (relation = schema.relation(key)) {
          relational_attributes[key] = relation;
        } else {
          simple_attributes[key] = value;
        }
      }
      if (_.size(simple_attributes)) {
        model_type.prototype._orm_original_fns.set.call(this, simple_attributes, options);
      }
      for (key in relational_attributes) {
        relation = relational_attributes[key];
        relation.set(this, key, attributes[key], options);
      }
      return this;
    },
    get: function(key, callback) {
      var relation, schema, value;
      if (model_type.schema) {
        schema = model_type.schema();
      }
      if (schema && (relation = schema.relation(key))) {
        return relation.get(this, key, callback);
      }
      value = model_type.prototype._orm_original_fns.get.call(this, key);
      if (callback) {
        callback(null, value);
      }
      return value;
    },
    toJSON: function(options) {
      var json, key, keys, relation, schema, value, _base, _i, _len;
      if (options == null) {
        options = {};
      }
      if (model_type.schema) {
        schema = model_type.schema();
      }
      this._orm || (this._orm = {});
      if (this._orm.json > 0) {
        return this.id;
      }
      (_base = this._orm).json || (_base.json = 0);
      this._orm.json++;
      json = {};
      keys = options.keys || this.whitelist || _.keys(this.attributes);
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        key = keys[_i];
        value = this.attributes[key];
        if (schema && (relation = schema.relation(key))) {
          relation.appendJSON(json, this);
        } else if (Utils.isCollection(value)) {
          json[key] = _.map(value.models, function(model) {
            if (model) {
              return model.toJSON(options);
            } else {
              return null;
            }
          });
        } else if (Utils.isModel(value)) {
          json[key] = value.toJSON(options);
        } else {
          json[key] = value;
        }
      }
      --this._orm.json;
      return json;
    },
    save: function(key, value, options) {
      var attributes, callback, _base;
      if (_.isFunction(callback = arguments[arguments.length - 1])) {
        switch (arguments.length) {
          case 1:
            attributes = {};
            options = Utils.wrapOptions({}, callback);
            break;
          case 2:
            attributes = key;
            options = Utils.wrapOptions({}, callback);
            break;
          case 3:
            attributes = key;
            options = Utils.wrapOptions(value, callback);
            break;
          case 4:
            (attributes = {})[key] = value;
            options = Utils.wrapOptions(options, callback);
        }
      } else {
        if (arguments.length === 0) {
          attributes = {};
          options = {};
        } else if (key === null || _.isObject(key)) {
          attributes = key;
          options = value;
        } else {
          (attributes = {})[key] = value;
        }
      }
      if (!this.isLoaded()) {
        return typeof options.error === "function" ? options.error(this, new Error("An unloaded model is trying to be saved: " + model_type.model_name)) : void 0;
      }
      this._orm || (this._orm = {});
      if (this._orm.save > 0) {
        if (this.id) {
          return typeof options.success === "function" ? options.success(this, {}, options) : void 0;
        }
        return typeof options.error === "function" ? options.error(this, new Error("Model is in a save loop: " + model_type.model_name)) : void 0;
      }
      (_base = this._orm).save || (_base.save = 0);
      this._orm.save++;
      this.set(attributes, options);
      attributes = {};
      return Utils.presaveBelongsToRelationships(this, (function(_this) {
        return function(err) {
          if (err) {
            return typeof options.error === "function" ? options.error(_this, err) : void 0;
          }
          return model_type.prototype._orm_original_fns.save.call(_this, attributes, Utils.wrapOptions(options, function(err, model, resp, options) {
            var queue, relation, schema, _fn, _ref;
            Utils.unset(_this, 'unsets');
            --_this._orm.save;
            if (err) {
              return typeof options.error === "function" ? options.error(_this, resp, options) : void 0;
            }
            queue = new Queue(1);
            if (model_type.schema) {
              schema = model_type.schema();
              _ref = schema.relations;
              _fn = function(relation) {
                return queue.defer(function(callback) {
                  return relation.save(_this, callback);
                });
              };
              for (key in _ref) {
                relation = _ref[key];
                _fn(relation);
              }
            }
            return queue.await(function(err) {
              var cache;
              if (err) {
                return typeof options.error === "function" ? options.error(_this, Error("Failed to save relations. " + err, options)) : void 0;
              }
              if (cache = model_type.cache) {
                cache.set(_this.id, _this);
              }
              return typeof options.success === "function" ? options.success(_this, resp, options) : void 0;
            });
          }));
        };
      })(this));
    },
    destroy: function(options) {
      var cache, callback, schema, _base;
      if (_.isFunction(callback = arguments[arguments.length - 1])) {
        switch (arguments.length) {
          case 1:
            options = Utils.wrapOptions({}, callback);
            break;
          case 2:
            options = Utils.wrapOptions(options, callback);
        }
      }
      if (cache = this.cache()) {
        cache.destroy(this.id);
      }
      if (!(model_type.schema && (schema = model_type.schema()))) {
        return model_type.prototype._orm_original_fns.destroy.call(this, options);
      }
      this._orm || (this._orm = {});
      if (this._orm.destroy > 0) {
        throw new Error("Model is in a destroy loop: " + model_type.model_name);
      }
      (_base = this._orm).destroy || (_base.destroy = 0);
      this._orm.destroy++;
      return model_type.prototype._orm_original_fns.destroy.call(this, Utils.wrapOptions(options, (function(_this) {
        return function(err, model, resp, options) {
          --_this._orm.destroy;
          if (err) {
            return typeof options.error === "function" ? options.error(_this, resp, options) : void 0;
          }
          return _this.patchRemove(function(err) {
            if (err) {
              return typeof options.error === "function" ? options.error(_this, new Error("Failed to destroy relations. " + err, options)) : void 0;
            }
            return typeof options.success === "function" ? options.success(_this, resp, options) : void 0;
          });
        };
      })(this)));
    },
    clone: function(options) {
      var cache, clone, key, keys, model, value, _base, _base1, _i, _len, _name, _ref;
      if (!model_type.schema) {
        return model_type.prototype._orm_original_fns.clone.apply(this, arguments);
      }
      options || (options = {});
      options._cache || (options._cache = {});
      cache = (_base = options._cache)[_name = this.modelName()] || (_base[_name] = {});
      this._orm || (this._orm = {});
      if (this._orm.clone > 0) {
        if (this.id) {
          return cache[this.id];
        } else {
          return model_type.prototype._orm_original_fns.clone.apply(this, arguments);
        }
      }
      (_base1 = this._orm).clone || (_base1.clone = 0);
      this._orm.clone++;
      if (this.id) {
        if (!(clone = cache[this.id])) {
          cache[this.id] = clone = new this.constructor();
        }
      } else {
        clone = new this.constructor();
      }
      if (this.attributes.id) {
        clone.id = this.attributes.id;
      }
      keys = options.keys || _.keys(this.attributes);
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        key = keys[_i];
        value = this.attributes[key];
        if (Utils.isCollection(value)) {
          if (!((_ref = clone.attributes[key]) != null ? _ref.values : void 0)) {
            clone.attributes[key] = new value.constructor();
          }
          clone.attributes[key].models = (function() {
            var _j, _len1, _ref1, _results;
            _ref1 = value.models;
            _results = [];
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              model = _ref1[_j];
              _results.push(_findOrClone(model, options));
            }
            return _results;
          })();
        } else if (Utils.isModel(value)) {
          clone.attributes[key] = _findOrClone(value, options);
        } else {
          clone.attributes[key] = value;
        }
      }
      --this._orm.clone;
      return clone;
    }
  };
  if (!model_type.prototype._orm_original_fns) {
    model_type.prototype._orm_original_fns = {};
    _results = [];
    for (key in overrides) {
      fn = overrides[key];
      model_type.prototype._orm_original_fns[key] = model_type.prototype[key];
      _results.push(model_type.prototype[key] = fn);
    }
    return _results;
  }
};
