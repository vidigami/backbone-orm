
/*
  backbone-orm.js 0.5.18
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var Backbone, DatabaseURL, Many, One, RELATION_VARIANTS, Schema, Utils, inflection, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

_ = require('underscore');

Backbone = require('backbone');

inflection = require('inflection');

One = require('./relations/one');

Many = require('./relations/many');

DatabaseURL = require('./database_url');

Utils = require('./utils');

RELATION_VARIANTS = {
  'hasOne': 'hasOne',
  'has_one': 'hasOne',
  'HasOne': 'hasOne',
  'belongsTo': 'belongsTo',
  'belongs_to': 'belongsTo',
  'BelongsTo': 'belongsTo',
  'hasMany': 'hasMany',
  'has_many': 'hasMany',
  'HasMany': 'hasMany'
};

module.exports = Schema = (function() {
  function Schema(model_type) {
    this.model_type = model_type;
    this.raw = _.clone(_.result(new this.model_type(), 'schema') || {});
    this.fields = {};
    this.relations = {};
    this.virtual_accessors = {};
  }

  Schema.prototype.initialize = function() {
    var info, key, relation, _ref, _ref1;
    if (this.is_initialized) {
      return;
    }
    this.is_initialized = true;
    _ref = this.raw;
    for (key in _ref) {
      info = _ref[key];
      this._parseField(key, info);
    }
    _ref1 = this.relations;
    for (key in _ref1) {
      relation = _ref1[key];
      relation.initialize();
    }
  };

  Schema.prototype.relation = function(key) {
    return this.relations[key] || this.virtual_accessors[key];
  };

  Schema.prototype.reverseRelation = function(reverse_key) {
    var key, relation, _ref;
    _ref = this.relations;
    for (key in _ref) {
      relation = _ref[key];
      if (relation.reverse_relation && (relation.reverse_relation.join_key === reverse_key)) {
        return relation.reverse_relation;
      }
    }
    return null;
  };

  Schema.prototype.columns = function() {
    var columns, key, relation, _ref;
    columns = _.keys(this.fields);
    if (!_.find(columns, function(column) {
      return column === 'id';
    })) {
      columns.push('id');
    }
    _ref = this.relations;
    for (key in _ref) {
      relation = _ref[key];
      if ((relation.type === 'belongsTo') && !relation.isVirtual() && !relation.isEmbedded()) {
        columns.push(relation.foreign_key);
      }
    }
    return columns;
  };

  Schema.prototype.joinTables = function() {
    var key, relation;
    return (function() {
      var _ref, _results;
      _ref = this.relations;
      _results = [];
      for (key in _ref) {
        relation = _ref[key];
        if (!relation.isVirtual() && relation.join_table) {
          _results.push(relation.join_table);
        }
      }
      return _results;
    }).call(this);
  };

  Schema.prototype.relatedModels = function() {
    var key, related_model_types, relation, _ref;
    related_model_types = [];
    _ref = this.relations;
    for (key in _ref) {
      relation = _ref[key];
      related_model_types.push(relation.reverse_model_type);
      if (relation.join_table) {
        related_model_types.push(relation.join_table);
      }
    }
    return related_model_types;
  };

  Schema.prototype.allColumns = function() {
    return this.columns();
  };

  Schema.prototype.allRelations = function() {
    return this.relatedModels();
  };

  Schema.prototype.generateBelongsTo = function(reverse_model_type) {
    var key, relation;
    key = inflection.underscore(reverse_model_type.model_name);
    if (relation = this.relations[key]) {
      return relation;
    }
    if (this.raw[key]) {
      relation = this._parseField(key, this.raw[key]);
      relation.initialize();
      return relation;
    }
    relation = this._parseField(key, this.raw[key] = [
      'belongsTo', reverse_model_type, {
        manual_fetch: true
      }
    ]);
    relation.initialize();
    return relation;
  };

  Schema.joinTableURL = function(relation) {
    var model_name1, model_name2;
    model_name1 = inflection.pluralize(inflection.underscore(relation.model_type.model_name));
    model_name2 = inflection.pluralize(inflection.underscore(relation.reverse_relation.model_type.model_name));
    if (model_name1.localeCompare(model_name2) < 0) {
      return "" + model_name1 + "_" + model_name2;
    } else {
      return "" + model_name2 + "_" + model_name1;
    }
  };

  Schema.prototype.generateJoinTable = function(relation) {
    var JoinTable, name, schema, url;
    schema = {};
    schema[relation.join_key] = [
      'Integer', {
        indexed: true
      }
    ];
    schema[relation.reverse_relation.join_key] = [
      'Integer', {
        indexed: true
      }
    ];
    url = Schema.joinTableURL(relation);
    name = inflection.pluralize(inflection.classify(url));
    try {
      JoinTable = (function(_super) {
        __extends(JoinTable, _super);

        function JoinTable() {
          return JoinTable.__super__.constructor.apply(this, arguments);
        }

        JoinTable.prototype.model_name = name;

        JoinTable.prototype.urlRoot = "" + ((new DatabaseURL(_.result(new relation.model_type, 'url'))).format({
          exclude_table: true
        })) + "/" + url;

        JoinTable.prototype.schema = schema;

        JoinTable.prototype.sync = relation.model_type.createSync(JoinTable);

        return JoinTable;

      })(Backbone.Model);
    } catch (_error) {
      JoinTable = (function(_super) {
        __extends(JoinTable, _super);

        function JoinTable() {
          return JoinTable.__super__.constructor.apply(this, arguments);
        }

        JoinTable.prototype.model_name = name;

        JoinTable.prototype.urlRoot = "/" + url;

        JoinTable.prototype.schema = schema;

        JoinTable.prototype.sync = relation.model_type.createSync(JoinTable);

        return JoinTable;

      })(Backbone.Model);
    }
    return JoinTable;
  };

  Schema.prototype._parseField = function(key, info) {
    var options, relation, type;
    options = this._fieldInfoToOptions(_.isFunction(info) ? info() : info);
    if (!options.type) {
      return this.fields[key] = options;
    }
    if (!(type = RELATION_VARIANTS[options.type])) {
      if (!_.isString(options.type)) {
        throw new Error("Unexpected type name is not a string: " + (Utils.inspect(options)));
      }
      return this.fields[key] = options;
    }
    options.type = type;
    relation = this.relations[key] = type === 'hasMany' ? new Many(this.model_type, key, options) : new One(this.model_type, key, options);
    if (relation.virtual_id_accessor) {
      this.virtual_accessors[relation.virtual_id_accessor] = relation;
    }
    if (type === 'belongsTo') {
      this.virtual_accessors[relation.foreign_key] = relation;
    }
    return relation;
  };

  Schema.prototype._fieldInfoToOptions = function(options) {
    var result;
    if (_.isString(options)) {
      return {
        type: options
      };
    }
    if (!_.isArray(options)) {
      return options;
    }
    result = {};
    if (_.isString(options[0])) {
      result.type = options[0];
      options = options.slice(1);
      if (options.length === 0) {
        return result;
      }
    }
    if (_.isFunction(options[0])) {
      result.reverse_model_type = options[0];
      options = options.slice(1);
    }
    if (options.length > 1) {
      throw new Error("Unexpected field options array: " + (Utils.inspect(options)));
    }
    if (options.length === 1) {
      _.extend(result, options[0]);
    }
    return result;
  };

  return Schema;

})();
