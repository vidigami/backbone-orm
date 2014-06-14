
/*
  backbone-orm.js 0.5.16
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var Backbone, Queue, Relation, Utils, inflection, _;

_ = require('underscore');

Backbone = require('backbone');

inflection = require('inflection');

Queue = require('../queue');

Utils = require('../utils');

module.exports = Relation = (function() {
  function Relation() {}

  Relation.prototype.isEmbedded = function() {
    return !!(this.embed || (this.reverse_relation && this.reverse_relation.embed));
  };

  Relation.prototype.isVirtual = function() {
    return !!(this.virtual || (this.reverse_relation && this.reverse_relation.virtual));
  };

  Relation.prototype.findOrGenerateJoinTable = function() {
    var join_table;
    if (join_table = this.join_table || this.reverse_relation.join_table) {
      return join_table;
    }
    return this.model_type.schema().generateJoinTable(this);
  };

  Relation.prototype._findOrGenerateReverseRelation = function() {
    var key_root, model_type, reverse_model_type, reverse_relation;
    model_type = this.model_type;
    reverse_model_type = this.reverse_model_type;
    if (!_.isFunction(reverse_model_type.schema)) {
      reverse_model_type.sync = model_type.createSync(reverse_model_type);
    }
    key_root = this.as || inflection.underscore(model_type.model_name);
    reverse_relation = reverse_model_type.relation(key_root);
    if (!reverse_relation) {
      reverse_relation = reverse_model_type.relation(inflection.singularize(key_root));
    }
    if (!reverse_relation) {
      reverse_relation = reverse_model_type.relation(inflection.pluralize(key_root));
    }
    if (!reverse_relation && (this.type !== 'belongsTo')) {
      reverse_relation = reverse_model_type.schema().generateBelongsTo(model_type);
    }
    if (reverse_relation && !reverse_relation.reverse_relation) {
      reverse_relation.reverse_relation = this;
    }
    return reverse_relation;
  };

  Relation.prototype._saveRelated = function(model, related_models, callback) {
    if (this.embed || !this.reverse_relation || (this.type === 'belongsTo')) {
      return callback();
    }
    if (this.isVirtual()) {
      return callback();
    }
    return this.cursor(model, this.key).toJSON((function(_this) {
      return function(err, json) {
        var added_id, added_ids, changes, queue, related_id, related_ids, related_json, related_model, test, _fn, _fn1, _fn2, _i, _j, _k, _len, _len1, _len2, _ref;
        if (err) {
          return callback(err);
        }
        if (!_.isArray(json)) {
          json = (json ? [json] : []);
        }
        queue = new Queue(1);
        related_ids = _.pluck(related_models, 'id');
        changes = _.groupBy(json, function(test) {
          if (_.contains(related_ids, test.id)) {
            return 'kept';
          } else {
            return 'removed';
          }
        });
        added_ids = changes.kept ? _.difference(related_ids, (function() {
          var _i, _len, _ref, _results;
          _ref = changes.kept;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            test = _ref[_i];
            _results.push(test.id);
          }
          return _results;
        })()) : related_ids;
        if (changes.removed) {
          if (_this.join_table) {
            queue.defer(function(callback) {
              var query, related_json;
              query = {};
              query[_this.reverse_relation.join_key] = {
                $in: (function() {
                  var _i, _len, _ref, _results;
                  _ref = changes.removed;
                  _results = [];
                  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                    related_json = _ref[_i];
                    _results.push(related_json[this.reverse_model_type.prototype.idAttribute]);
                  }
                  return _results;
                }).call(_this)
              };
              return _this.join_table.destroy(query, callback);
            });
          } else {
            _ref = changes.removed;
            _fn = function(related_json) {
              return queue.defer(function(callback) {
                related_json[_this.reverse_relation.foreign_key] = null;
                return Utils.modelJSONSave(related_json, _this.reverse_model_type, callback);
              });
            };
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              related_json = _ref[_i];
              _fn(related_json);
            }
          }
        }
        if (added_ids.length) {
          if (_this.join_table) {
            _fn1 = function(related_id) {
              return queue.defer(function(callback) {
                var attributes, join;
                attributes = {};
                attributes[_this.foreign_key] = model.id;
                attributes[_this.reverse_relation.foreign_key] = related_id;
                join = new _this.join_table(attributes);
                return join.save(callback);
              });
            };
            for (_j = 0, _len1 = added_ids.length; _j < _len1; _j++) {
              related_id = added_ids[_j];
              _fn1(related_id);
            }
          } else {
            _fn2 = function(related_model) {
              return queue.defer(function(callback) {
                return related_model.save(function(err, saved_model) {
                  var cache;
                  if (!err && (cache = _this.reverse_model_type.cache)) {
                    cache.set(saved_model.id, saved_model);
                  }
                  return callback(err);
                });
              });
            };
            for (_k = 0, _len2 = added_ids.length; _k < _len2; _k++) {
              added_id = added_ids[_k];
              related_model = _.find(related_models, function(test) {
                return test.id === added_id;
              });
              if (!_this.reverse_relation._hasChanged(related_model)) {
                continue;
              }
              _fn2(related_model);
            }
          }
        }
        return queue.await(callback);
      };
    })(this));
  };

  return Relation;

})();
