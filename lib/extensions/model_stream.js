
/*
  backbone-orm.js 0.5.16
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var ModelStream, e, stream,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

try {
  stream = require('stream');
} catch (_error) {
  e = _error;
}

if (!(stream != null ? stream.Readable : void 0)) {
  module.exports = null;
  return;
}

module.exports = ModelStream = (function(_super) {
  __extends(ModelStream, _super);

  function ModelStream(model_type, query) {
    this.model_type = model_type;
    this.query = query != null ? query : {};
    ModelStream.__super__.constructor.call(this, {
      objectMode: true
    });
  }

  ModelStream.prototype._read = function() {
    var done;
    if (this.ended || this.started) {
      return;
    }
    this.started = true;
    done = (function(_this) {
      return function(err) {
        _this.ended = true;
        if (err) {
          _this.emit('error', err);
        }
        return _this.push(null);
      };
    })(this);
    return this.model_type.each(this.query, ((function(_this) {
      return function(model, callback) {
        _this.push(model);
        return callback();
      };
    })(this)), done);
  };

  return ModelStream;

})(stream.Readable);
