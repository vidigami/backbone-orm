
/*
  backbone-orm.js 0.5.18
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var Backbone, Many, Queue, Utils, inflection, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Backbone = require('backbone');

_ = require('underscore');

inflection = require('inflection');

Queue = require('../queue');

Utils = require('../utils');

module.exports = Many = (function(_super) {
  __extends(Many, _super);

  function Many(model_type, key, options) {
    var Collection, reverse_model_type, value;
    this.model_type = model_type;
    this.key = key;
    for (key in options) {
      value = options[key];
      this[key] = value;
    }
    this.virtual_id_accessor || (this.virtual_id_accessor = "" + (inflection.singularize(this.key)) + "_ids");
    if (!this.join_key) {
      this.join_key = this.foreign_key || inflection.foreign_key(this.model_type.model_name);
    }
    if (!this.foreign_key) {
      this.foreign_key = inflection.foreign_key(this.as || this.model_type.model_name);
    }
    if (!this.collection_type) {
      reverse_model_type = this.reverse_model_type;
      Collection = (function(_super1) {
        __extends(Collection, _super1);

        function Collection() {
          return Collection.__super__.constructor.apply(this, arguments);
        }

        Collection.prototype.model = reverse_model_type;

        return Collection;

      })(Backbone.Collection);
      this.collection_type = Collection;
    }
  }

  Many.prototype.initialize = function() {
    var _ref;
    this.reverse_relation = this._findOrGenerateReverseRelation(this);
    if (this.embed && this.reverse_relation && this.reverse_relation.embed) {
      throw new Error("Both relationship directions cannot embed (" + this.model_type.model_name + " and " + this.reverse_model_type.model_name + "). Choose one or the other.");
    }
    if (((_ref = this.reverse_relation) != null ? _ref.type : void 0) === 'hasOne') {
      throw new Error("The reverse of a hasMany relation should be `belongsTo`, not `hasOne` (" + this.model_type.model_name + " and " + this.reverse_model_type.model_name + ").");
    }
    if (this.reverse_relation.type === 'hasMany') {
      return this.join_table = this.findOrGenerateJoinTable(this);
    }
  };

  Many.prototype.initializeModel = function(model) {
    if (!model.isLoadedExists(this.key)) {
      model.setLoaded(this.key, false);
    }
    return this._bindBacklinks(model);
  };

  Many.prototype.releaseModel = function(model) {
    this._unbindBacklinks(model);
    return delete model._orm;
  };

  Many.prototype.set = function(model, key, value, options) {
    var collection, item, model_ids, models, previous_models, related_model, _i, _len;
    if (!((key === this.key) || (key === this.virtual_id_accessor) || (key === this.foreign_key))) {
      throw new Error("Many.set: Unexpected key " + key + ". Expecting: " + this.key + " or " + this.virtual_id_accessor + " or " + this.foreign_key);
    }
    collection = this._bindBacklinks(model);
    if (Utils.isCollection(value)) {
      value = value.models;
    }
    if (_.isUndefined(value)) {
      value = [];
    }
    if (!_.isArray(value)) {
      throw new Error("HasMany.set: Unexpected type to set " + key + ". Expecting array: " + (Utils.inspect(value)));
    }
    Utils.orSet(model, 'rel_dirty', {})[this.key] = true;
    model.setLoaded(this.key, _.all(value, function(item) {
      return Utils.dataId(item) !== item;
    }));
    models = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = value.length; _i < _len; _i++) {
        item = value[_i];
        _results.push((related_model = collection.get(Utils.dataId(item))) ? Utils.updateModel(related_model, item) : Utils.updateOrNew(item, this.reverse_model_type));
      }
      return _results;
    }).call(this);
    model.setLoaded(this.key, _.all(models, function(model) {
      return model.isLoaded();
    }));
    previous_models = _.clone(collection.models);
    collection.reset(models);
    if (this.reverse_relation.type === 'belongsTo') {
      model_ids = _.pluck(models, 'id');
      for (_i = 0, _len = previous_models.length; _i < _len; _i++) {
        related_model = previous_models[_i];
        if (!_.contains(model_ids, related_model.id)) {
          related_model.set(this.foreign_key, null);
        }
      }
    }
    return this;
  };

  Many.prototype.get = function(model, key, callback) {
    var collection, is_loaded, result, returnValue;
    if (!((key === this.key) || (key === this.virtual_id_accessor) || (key === this.foreign_key))) {
      throw new Error("Many.get: Unexpected key " + key + ". Expecting: " + this.key + " or " + this.virtual_id_accessor + " or " + this.foreign_key);
    }
    collection = this._ensureCollection(model);
    returnValue = (function(_this) {
      return function() {
        var related_model, _i, _len, _ref, _results;
        if (key === _this.virtual_id_accessor) {
          _ref = collection.models;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            related_model = _ref[_i];
            _results.push(related_model.id);
          }
          return _results;
        } else {
          return collection;
        }
      };
    })(this);
    if (callback && !this.isVirtual() && !this.manual_fetch && !(is_loaded = model.isLoaded(this.key))) {
      this.cursor(model, this.key).toJSON((function(_this) {
        return function(err, json) {
          var cache, model_json, related_model, result, _i, _j, _len, _len1, _ref;
          if (err) {
            return callback(err);
          }
          model.setLoaded(_this.key, true);
          for (_i = 0, _len = json.length; _i < _len; _i++) {
            model_json = json[_i];
            if (related_model = collection.get(model_json[_this.reverse_model_type.prototype.idAttribute])) {
              related_model.set(model_json);
            } else {
              collection.add(related_model = Utils.updateOrNew(model_json, _this.reverse_model_type));
            }
          }
          if (cache = _this.reverse_model_type.cache) {
            _ref = collection.models;
            for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
              related_model = _ref[_j];
              cache.set(related_model.id, related_model);
            }
          }
          result = returnValue();
          return callback(null, result.models ? result.models : result);
        };
      })(this));
    }
    result = returnValue();
    if (callback && (is_loaded || this.manual_fetch)) {
      callback(null, result.models ? result.models : result);
    }
    return result;
  };

  Many.prototype.save = function(model, callback) {
    var collection;
    if (!this._hasChanged(model)) {
      return callback();
    }
    delete Utils.orSet(model, 'rel_dirty', {})[this.key];
    collection = this._ensureCollection(model);
    return this._saveRelated(model, _.clone(collection.models), callback);
  };

  Many.prototype.appendJSON = function(json, model) {
    var collection, json_key;
    if (this.isVirtual()) {
      return;
    }
    collection = this._ensureCollection(model);
    json_key = this.embed ? this.key : this.virtual_id_accessor;
    if (this.embed) {
      return json[json_key] = collection.toJSON();
    }
  };

  Many.prototype.add = function(model, related_model) {
    var collection, current_related_model;
    collection = this._ensureCollection(model);
    current_related_model = collection.get(related_model.id);
    if (current_related_model === related_model) {
      return;
    }
    if (current_related_model) {
      collection.remove(current_related_model);
    }
    if (this.reverse_model_type.cache && related_model.id) {
      this.reverse_model_type.cache.set(related_model.id, related_model);
    }
    return collection.add(related_model);
  };

  Many.prototype.remove = function(model, related_model) {
    var collection, current_related_model;
    collection = this._ensureCollection(model);
    if (!(current_related_model = collection.get(related_model.id))) {
      return;
    }
    return collection.remove(current_related_model);
  };

  Many.prototype.patchAdd = function(model, relateds, callback) {
    var collection, item, query, queue, related, related_id, related_ids, related_model, _fn, _i, _j, _len, _len1;
    if (!model.id) {
      return callback(new Error("Many.patchAdd: model has null id for: " + this.key));
    }
    if (!relateds) {
      return callback(new Error("Many.patchAdd: missing model for: " + this.key));
    }
    if (!_.isArray(relateds)) {
      relateds = [relateds];
    }
    collection = this._ensureCollection(model);
    relateds = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = relateds.length; _i < _len; _i++) {
        item = relateds[_i];
        _results.push((related_model = collection.get(Utils.dataId(item))) ? Utils.updateModel(related_model, item) : Utils.updateOrNew(item, this.reverse_model_type));
      }
      return _results;
    }).call(this);
    related_ids = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = relateds.length; _i < _len; _i++) {
        related = relateds[_i];
        _results.push(Utils.dataId(related));
      }
      return _results;
    })();
    collection.add(relateds);
    if (model.isLoaded(this.key)) {
      for (_i = 0, _len = relateds.length; _i < _len; _i++) {
        related = relateds[_i];
        if (!related.isLoaded()) {
          model.setLoaded(this.key, false);
          break;
        }
      }
    }
    if (this.join_table) {
      queue = new Queue(1);
      _fn = (function(_this) {
        return function(related_id) {
          return queue.defer(function(callback) {
            var add, query;
            if (!related_id) {
              return callback(new Error("Many.patchAdd: cannot add an new model. Please save first."));
            }
            add = function(callback) {
              var attributes, join;
              attributes = {};
              attributes[_this.foreign_key] = model.id;
              attributes[_this.reverse_relation.foreign_key] = related_id;
              join = new _this.join_table(attributes);
              return join.save(callback);
            };
            if (_this.reverse_relation.type === 'hasMany') {
              return add(callback);
            }
            (query = {
              $one: true
            })[_this.reverse_relation.foreign_key] = related_id;
            return _this.join_table.cursor(query).toJSON(function(err, join_table_json) {
              if (err) {
                return callback(err);
              }
              if (!join_table_json) {
                return add(callback);
              }
              if (join_table_json[_this.foreign_key] === model.id) {
                return callback();
              }
              join_table_json[_this.foreign_key] = model.id;
              return Utils.modelJSONSave(join_table_json, _this.join_table, callback);
            });
          });
        };
      })(this);
      for (_j = 0, _len1 = related_ids.length; _j < _len1; _j++) {
        related_id = related_ids[_j];
        _fn(related_id);
      }
      return queue.await(callback);
    } else {
      query = {
        id: {
          $in: related_ids
        }
      };
      return this.reverse_model_type.cursor(query).toJSON((function(_this) {
        return function(err, related_jsons) {
          var related_json, _fn1, _k, _len2;
          queue = new Queue(1);
          _fn1 = function(related_json) {
            return queue.defer(function(callback) {
              related_json[_this.reverse_relation.foreign_key] = model.id;
              return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
            });
          };
          for (_k = 0, _len2 = related_jsons.length; _k < _len2; _k++) {
            related_json = related_jsons[_k];
            _fn1(related_json);
          }
          return queue.await(callback);
        };
      })(this));
    }
  };

  Many.prototype.patchRemove = function(model, relateds, callback) {
    var cache, collection, current_related_model, json, query, related, related_ids, related_model, related_models, _i, _j, _k, _len, _len1, _len2, _ref;
    if (!model.id) {
      return callback(new Error("Many.patchRemove: model has null id for: " + this.key));
    }
    if (arguments.length === 2) {
      callback = relateds;
      if (!this.reverse_relation) {
        return callback();
      }
      if (Utils.isModel(model)) {
        delete Utils.orSet(model, 'rel_dirty', {})[this.key];
        collection = this._ensureCollection(model);
        related_models = _.clone(collection.models);
      } else {
        related_models = (function() {
          var _i, _len, _ref, _results;
          _ref = model[this.key] || [];
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            json = _ref[_i];
            _results.push(new this.reverse_model_type(json));
          }
          return _results;
        }).call(this);
      }
      for (_i = 0, _len = related_models.length; _i < _len; _i++) {
        related_model = related_models[_i];
        related_model.set(this.foreign_key, null);
        if (cache = related_model.cache()) {
          cache.set(related_model.id, related_model);
        }
      }
      if (this.join_table) {
        (query = {})[this.join_key] = model.id;
        return this.join_table.destroy(query, callback);
      } else {
        (query = {})[this.reverse_relation.foreign_key] = model.id;
        this.reverse_model_type.cursor(query).toJSON((function(_this) {
          return function(err, json) {
            var queue, related_json, _fn, _j, _len1;
            if (err) {
              return callback(err);
            }
            queue = new Queue(1);
            _fn = function(related_json) {
              return queue.defer(function(callback) {
                related_json[_this.reverse_relation.foreign_key] = null;
                return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
              });
            };
            for (_j = 0, _len1 = json.length; _j < _len1; _j++) {
              related_json = json[_j];
              _fn(related_json);
            }
            return queue.await(callback);
          };
        })(this));
      }
      return;
    }
    if (this.isEmbedded()) {
      return callback(new Error('Many.patchRemove: embedded relationships are not supported'));
    }
    if (!relateds) {
      return callback(new Error('One.patchRemove: missing model for remove'));
    }
    if (!_.isArray(relateds)) {
      relateds = [relateds];
    }
    collection = this._ensureCollection(model);
    for (_j = 0, _len1 = relateds.length; _j < _len1; _j++) {
      related = relateds[_j];
      _ref = collection.models;
      for (_k = 0, _len2 = _ref.length; _k < _len2; _k++) {
        current_related_model = _ref[_k];
        if (Utils.dataIsSameModel(current_related_model, related)) {
          collection.remove(current_related_model);
          break;
        }
      }
    }
    related_ids = (function() {
      var _l, _len3, _results;
      _results = [];
      for (_l = 0, _len3 = relateds.length; _l < _len3; _l++) {
        related = relateds[_l];
        _results.push(Utils.dataId(related));
      }
      return _results;
    })();
    if (this.join_table) {
      query = {};
      query[this.join_key] = model.id;
      query[this.reverse_relation.join_key] = {
        $in: related_ids
      };
      return this.join_table.destroy(query, callback);
    } else {
      query = {};
      query[this.reverse_relation.foreign_key] = model.id;
      query.id = {
        $in: related_ids
      };
      return this.reverse_model_type.cursor(query).toJSON((function(_this) {
        return function(err, json) {
          var queue, related_json, _fn, _l, _len3;
          if (err) {
            return callback(err);
          }
          queue = new Queue(1);
          _fn = function(related_json) {
            return queue.defer(function(callback) {
              related_json[_this.reverse_relation.foreign_key] = null;
              return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
            });
          };
          for (_l = 0, _len3 = json.length; _l < _len3; _l++) {
            related_json = json[_l];
            _fn(related_json);
          }
          return queue.await(callback);
        };
      })(this));
    }
  };

  Many.prototype.cursor = function(model, key, query) {
    var json;
    json = Utils.isModel(model) ? model.attributes : model;
    (query = _.clone(query || {}))[this.join_table ? this.join_key : this.reverse_relation.foreign_key] = json[this.model_type.prototype.idAttribute];
    if (key === this.virtual_id_accessor) {
      (query.$values || (query.$values = [])).push('id');
    }
    return this.reverse_model_type.cursor(query);
  };

  Many.prototype._bindBacklinks = function(model) {
    var collection, events, method, _i, _len, _ref;
    if ((collection = model.attributes[this.key]) instanceof this.collection_type) {
      return collection;
    }
    collection = model.attributes[this.key] = new this.collection_type();
    if (!this.reverse_relation) {
      return collection;
    }
    events = Utils.set(collection, 'events', {});
    events.add = (function(_this) {
      return function(related_model) {
        var current_model, is_current;
        if (_this.reverse_relation.add) {
          return _this.reverse_relation.add(related_model, model);
        } else {
          current_model = related_model.get(_this.reverse_relation.key);
          is_current = model.id && (Utils.dataId(current_model) === model.id);
          if (!is_current || (is_current && !current_model.isLoaded())) {
            return related_model.set(_this.reverse_relation.key, model);
          }
        }
      };
    })(this);
    events.remove = (function(_this) {
      return function(related_model) {
        var current_model;
        if (_this.reverse_relation.remove) {
          return _this.reverse_relation.remove(related_model, model);
        } else {
          current_model = related_model.get(_this.reverse_relation.key);
          if (Utils.dataId(current_model) === model.id) {
            return related_model.set(_this.reverse_relation.key, null);
          }
        }
      };
    })(this);
    events.reset = (function(_this) {
      return function(collection, options) {
        var added, changes, current_models, previous_models, related_model, _i, _j, _len, _len1, _ref, _results;
        current_models = collection.models;
        previous_models = options.previousModels || [];
        changes = _.groupBy(previous_models, function(test) {
          if (!!_.find(current_models, function(current_model) {
            return current_model.id === test.id;
          })) {
            return 'kept';
          } else {
            return 'removed';
          }
        });
        added = changes.kept ? _.select(current_models, function(test) {
          return !_.find(changes.kept, function(keep_model) {
            return keep_model.id === test.id;
          });
        }) : current_models;
        if (changes.removed) {
          _ref = changes.removed;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            related_model = _ref[_i];
            events.remove(related_model);
          }
        }
        _results = [];
        for (_j = 0, _len1 = added.length; _j < _len1; _j++) {
          related_model = added[_j];
          _results.push(events.add(related_model));
        }
        return _results;
      };
    })(this);
    _ref = ['add', 'remove', 'reset'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      method = _ref[_i];
      collection.on(method, events[method]);
    }
    return collection;
  };

  Many.prototype._unbindBacklinks = function(model) {
    var collection, events, method, _i, _len, _ref;
    if (!(events = Utils.get(model, 'events'))) {
      return;
    }
    Utils.unset(model, 'events');
    collection = model.attributes[this.key];
    collection.models.splice();
    events = _.clone();
    _ref = ['add', 'remove', 'reset'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      method = _ref[_i];
      collection.off(method, events[method]);
      events[method] = null;
    }
  };

  Many.prototype._ensureCollection = function(model) {
    return this._bindBacklinks(model);
  };

  Many.prototype._hasChanged = function(model) {
    var collection, _i, _len, _ref;
    return !!Utils.orSet(model, 'rel_dirty', {})[this.key] || model.hasChanged(this.key);
    if (!this.reverse_relation) {
      return false;
    }
    collection = this._ensureCollection(model);
    _ref = model.models;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      model = _ref[_i];
      if (model.hasChanged(this.reverse_relation.foreign_key)) {
        return true;
      }
    }
    return false;
  };

  return Many;

})(require('./relation'));
