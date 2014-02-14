
/*
  backbone-orm.js 0.5.8
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
 */
var ModelTypeID, crypto, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

_ = require('underscore');

crypto = require('crypto');

module.exports = ModelTypeID = (function() {
  function ModelTypeID() {
    this.generate = __bind(this.generate, this);
    this.modelID = __bind(this.modelID, this);
    this.reset = __bind(this.reset, this);
    this.configure = __bind(this.configure, this);
    this.enabled = false;
    this.ids = {};
  }

  ModelTypeID.prototype.configure = function(options) {
    if (options == null) {
      options = {};
    }
    this.enabled = options.enabled;
    return this;
  };

  ModelTypeID.prototype.reset = function() {
    this.ids = {};
    return this;
  };

  ModelTypeID.prototype.modelID = function(model_type) {
    var e, name_url, url;
    try {
      url = _.result(model_type.prototype, 'url');
    } catch (_error) {
      e = _error;
    }
    name_url = "" + (url || '') + "_" + model_type.model_name;
    return crypto.createHash('md5').update(name_url).digest('hex');
  };

  ModelTypeID.prototype.generate = function(model_type) {
    var id;
    if (!(id = model_type.model_type_id)) {
      id = this.modelID(model_type);
      if (this.enabled && this.ids[id] && this.ids[id] !== model_type) {
        throw new Error("Duplicate model name / url combination: " + model_type.model_name + ", " + (_.result(model_type.prototype, 'url')) + ". Set a unique model_name property on one of the conflicting models.");
      }
    }
    this.ids[id] = model_type;
    return id;
  };

  return ModelTypeID;

})();
