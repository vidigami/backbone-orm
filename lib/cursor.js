
/*
  backbone-orm.js 0.5.13
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var CURSOR_KEYS, Cursor, QueryCache, Utils, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

_ = require('underscore');

QueryCache = require('./cache/singletons').QueryCache;

Utils = require('./utils');

CURSOR_KEYS = ['$count', '$exists', '$zero', '$one', '$offset', '$limit', '$page', '$sort', '$white_list', '$select', '$include', '$values', '$ids'];

module.exports = Cursor = (function() {
  function Cursor(query, options) {
    this.relatedModelTypesInQuery = __bind(this.relatedModelTypesInQuery, this);
    var key, parsed_query, value, _i, _len, _ref;
    for (key in options) {
      value = options[key];
      this[key] = value;
    }
    parsed_query = Cursor.parseQuery(query, this.model_type);
    this._find = parsed_query.find;
    this._cursor = parsed_query.cursor;
    _ref = ['$white_list', '$select', '$values'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      key = _ref[_i];
      if (this._cursor[key] && !_.isArray(this._cursor[key])) {
        this._cursor[key] = [this._cursor[key]];
      }
    }
  }

  Cursor.validateQuery = function(query, memo, model_type) {
    var full_key, key, value, _results;
    _results = [];
    for (key in query) {
      value = query[key];
      if (!(_.isUndefined(value) || _.isObject(value))) {
        continue;
      }
      full_key = memo ? "" + memo + "." + key : key;
      if (_.isUndefined(value)) {
        throw new Error("Unexpected undefined for query key '" + full_key + "' on " + (model_type != null ? model_type.model_name : void 0));
      }
      if (_.isObject(value)) {
        _results.push(Cursor.validateQuery(value, full_key, model_type));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  Cursor.parseQuery = function(query, model_type) {
    var e, key, parsed_query, value;
    if (!query) {
      return {
        find: {},
        cursor: {}
      };
    } else if (!_.isObject(query)) {
      return {
        find: {
          id: query
        },
        cursor: {
          $one: true
        }
      };
    } else if (query.find || query.cursor) {
      return {
        find: query.find || {},
        cursor: query.cursor || {}
      };
    } else {
      try {
        Cursor.validateQuery(query, null, model_type);
      } catch (_error) {
        e = _error;
        throw new Error("Error: " + e + ". Query: ", query);
      }
      parsed_query = {
        find: {},
        cursor: {}
      };
      for (key in query) {
        value = query[key];
        if (key[0] !== '$') {
          parsed_query.find[key] = value;
        } else {
          parsed_query.cursor[key] = value;
        }
      }
      return parsed_query;
    }
  };

  Cursor.prototype.offset = function(offset) {
    this._cursor.$offset = offset;
    return this;
  };

  Cursor.prototype.limit = function(limit) {
    this._cursor.$limit = limit;
    return this;
  };

  Cursor.prototype.sort = function(sort) {
    this._cursor.$sort = sort;
    return this;
  };

  Cursor.prototype.whiteList = function(args) {
    var keys;
    keys = _.flatten(arguments);
    this._cursor.$white_list = this._cursor.$white_list ? _.intersection(this._cursor.$white_list, keys) : keys;
    return this;
  };

  Cursor.prototype.select = function(args) {
    var keys;
    keys = _.flatten(arguments);
    this._cursor.$select = this._cursor.$select ? _.intersection(this._cursor.$select, keys) : keys;
    return this;
  };

  Cursor.prototype.include = function(args) {
    var keys;
    keys = _.flatten(arguments);
    this._cursor.$include = this._cursor.$include ? _.intersection(this._cursor.$include, keys) : keys;
    return this;
  };

  Cursor.prototype.values = function(args) {
    var keys;
    keys = _.flatten(arguments);
    this._cursor.$values = this._cursor.$values ? _.intersection(this._cursor.$values, keys) : keys;
    return this;
  };

  Cursor.prototype.ids = function() {
    this._cursor.$values = ['id'];
    return this;
  };

  Cursor.prototype.count = function(callback) {
    return this.execWithCursorQuery('$count', 'toJSON', callback);
  };

  Cursor.prototype.exists = function(callback) {
    return this.execWithCursorQuery('$exists', 'toJSON', callback);
  };

  Cursor.prototype.toModel = function(callback) {
    return this.execWithCursorQuery('$one', 'toModels', callback);
  };

  Cursor.prototype.toModels = function(callback) {
    if (this._cursor.$values) {
      return callback(new Error("Cannot call toModels on cursor with values for model " + this.model_type.model_name + ". Values: " + (Utils.inspect(this._cursor.$values))));
    }
    return this.toJSON((function(_this) {
      return function(err, json) {
        if (err) {
          return callback(err);
        }
        if (_this._cursor.$one && !json) {
          return callback(null, null);
        }
        if (!_.isArray(json)) {
          json = [json];
        }
        return _this.prepareIncludes(json, function(err, json) {
          var can_cache, item, model, models;
          if (can_cache = !(_this._cursor.$select || _this._cursor.$whitelist)) {
            models = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = json.length; _i < _len; _i++) {
                item = json[_i];
                _results.push(Utils.updateOrNew(item, this.model_type));
              }
              return _results;
            }).call(_this);
          } else {
            models = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = json.length; _i < _len; _i++) {
                item = json[_i];
                _results.push((model = new this.model_type(this.model_type.prototype.parse(item)), model.setPartial(true), model));
              }
              return _results;
            }).call(_this);
          }
          return callback(null, _this._cursor.$one ? models[0] : models);
        });
      };
    })(this));
  };

  Cursor.prototype.toJSON = function(callback) {
    var parsed_query;
    parsed_query = _.extend({}, _.pick(this._cursor, CURSOR_KEYS), this._find);
    return QueryCache.get(this.model_type, parsed_query, (function(_this) {
      return function(err, cached_result) {
        var model_types;
        if (err) {
          return callback(err);
        }
        if (!_.isUndefined(cached_result)) {
          return callback(null, cached_result);
        }
        model_types = _this.relatedModelTypesInQuery();
        return _this.queryToJSON(function(err, json) {
          if (err) {
            return callback(err);
          }
          if (!_.isNull(json)) {
            return QueryCache.set(_this.model_type, parsed_query, model_types, json, function(err) {
              if (err) {
                console.log("Error setting query cache: " + err);
              }
              return callback(null, json);
            });
          } else {
            return callback(null, json);
          }
        });
      };
    })(this));
  };

  Cursor.prototype.queryToJSON = function(callback) {
    throw new Error('toJSON must be implemented by a concrete cursor for a Backbone Sync type');
  };

  Cursor.prototype.hasCursorQuery = function(key) {
    return this._cursor[key] || (this._cursor[key] === '');
  };

  Cursor.prototype.execWithCursorQuery = function(key, method, callback) {
    var value;
    value = this._cursor[key];
    this._cursor[key] = true;
    return this[method]((function(_this) {
      return function(err, json) {
        if (_.isUndefined(value)) {
          delete _this._cursor[key];
        } else {
          _this._cursor[key] = value;
        }
        return callback(err, json);
      };
    })(this));
  };

  Cursor.prototype.relatedModelTypesInQuery = function() {
    var key, related_fields, related_model_types, relation, relation_key, reverse_relation, value, _i, _len, _ref, _ref1, _ref2;
    related_fields = [];
    related_model_types = [];
    _ref = this._find;
    for (key in _ref) {
      value = _ref[key];
      if (key.indexOf('.') > 0) {
        _ref1 = key.split('.'), relation_key = _ref1[0], key = _ref1[1];
        related_fields.push(relation_key);
      } else if ((reverse_relation = this.model_type.reverseRelation(key)) && reverse_relation.join_table) {
        related_model_types.push(reverse_relation.model_type);
        related_model_types.push(reverse_relation.join_table);
      }
    }
    if ((_ref2 = this._cursor) != null ? _ref2.$include : void 0) {
      related_fields = related_fields.concat(this._cursor.$include);
    }
    for (_i = 0, _len = related_fields.length; _i < _len; _i++) {
      relation_key = related_fields[_i];
      if (relation = this.model_type.relation(relation_key)) {
        related_model_types.push(relation.reverse_model_type);
        if (relation.join_table) {
          related_model_types.push(relation.join_table);
        }
      }
    }
    return related_model_types;
  };

  Cursor.prototype.selectResults = function(json) {
    var $select, $values, item, key;
    if (this._cursor.$one) {
      json = json.slice(0, 1);
    }
    if (this._cursor.$values) {
      $values = this._cursor.$white_list ? _.intersection(this._cursor.$values, this._cursor.$white_list) : this._cursor.$values;
      if (this._cursor.$values.length === 1) {
        key = this._cursor.$values[0];
        json = $values.length ? (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = json.length; _i < _len; _i++) {
            item = json[_i];
            _results.push(item.hasOwnProperty(key) ? item[key] : null);
          }
          return _results;
        })() : _.map(json, function() {
          return null;
        });
      } else {
        json = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = json.length; _i < _len; _i++) {
            item = json[_i];
            _results.push((function() {
              var _j, _len1, _results1;
              _results1 = [];
              for (_j = 0, _len1 = $values.length; _j < _len1; _j++) {
                key = $values[_j];
                if (item.hasOwnProperty(key)) {
                  _results1.push(item[key]);
                }
              }
              return _results1;
            })());
          }
          return _results;
        })();
      }
    } else if (this._cursor.$select) {
      $select = this._cursor.$white_list ? _.intersection(this._cursor.$select, this._cursor.$white_list) : this._cursor.$select;
      json = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = json.length; _i < _len; _i++) {
          item = json[_i];
          _results.push(_.pick(item, $select));
        }
        return _results;
      })();
    } else if (this._cursor.$white_list) {
      json = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = json.length; _i < _len; _i++) {
          item = json[_i];
          _results.push(_.pick(item, this._cursor.$white_list));
        }
        return _results;
      }).call(this);
    }
    if (this.hasCursorQuery('$page')) {
      return json;
    }
    if (this._cursor.$one) {
      return json[0] || null;
    } else {
      return json;
    }
  };

  Cursor.prototype.selectFromModels = function(models, callback) {
    var $select, item, model;
    if (this._cursor.$select) {
      $select = this._cursor.$white_list ? _.intersection(this._cursor.$select, this._cursor.$white_list) : this._cursor.$select;
      models = ((function() {
        var _i, _len, _results;
        model = new this.model_type(_.pick(model.attributes, $select));
        model.setPartial(true);
        _results = [];
        for (_i = 0, _len = models.length; _i < _len; _i++) {
          item = models[_i];
          _results.push(model);
        }
        return _results;
      }).call(this));
    } else if (this._cursor.$white_list) {
      models = ((function() {
        var _i, _len, _results;
        model = new this.model_type(_.pick(model.attributes, this._cursor.$white_list));
        model.setPartial(true);
        _results = [];
        for (_i = 0, _len = models.length; _i < _len; _i++) {
          item = models[_i];
          _results.push(model);
        }
        return _results;
      }).call(this));
    }
    return models;
  };

  Cursor.prototype.prepareIncludes = function(json, callback) {
    var findOrNew, include, item, model_json, related_json, relation, schema, shared_related_models, _i, _j, _len, _len1, _ref;
    if (!_.isArray(this._cursor.$include) || _.isEmpty(this._cursor.$include)) {
      return callback(null, json);
    }
    schema = this.model_type.schema();
    shared_related_models = {};
    findOrNew = (function(_this) {
      return function(related_json, reverse_model_type) {
        var related_id;
        related_id = related_json[reverse_model_type.prototype.idAttribute];
        if (!shared_related_models[related_id]) {
          if (reverse_model_type.cache) {
            if (!(shared_related_models[related_id] = reverse_model_type.cache.get(related_id))) {
              reverse_model_type.cache.set(related_id, shared_related_models[related_id] = new reverse_model_type(related_json));
            }
          } else {
            shared_related_models[related_id] = new reverse_model_type(related_json);
          }
        }
        return shared_related_models[related_id];
      };
    })(this);
    _ref = this._cursor.$include;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      include = _ref[_i];
      relation = schema.relation(include);
      shared_related_models = {};
      for (_j = 0, _len1 = json.length; _j < _len1; _j++) {
        model_json = json[_j];
        if (_.isArray(related_json = model_json[include])) {
          model_json[include] = (function() {
            var _k, _len2, _results;
            _results = [];
            for (_k = 0, _len2 = related_json.length; _k < _len2; _k++) {
              item = related_json[_k];
              _results.push(findOrNew(item, relation.reverse_model_type));
            }
            return _results;
          })();
        } else if (related_json) {
          model_json[include] = findOrNew(related_json, relation.reverse_model_type);
        }
      }
    }
    return callback(null, json);
  };

  return Cursor;

})();
