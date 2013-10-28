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
    """

  end: """
    if (typeof exports == 'object') {
      module.exports = require('bborm/index');
    } else if (typeof define == 'function' && define.amd) {
      define('bborm', ['underscore', 'backbone', 'moment', 'inflection'], function(){ return require('bborm/index'); });
    } else {
      this['bborm'] = require('bborm/index');
    }
    }).call(this);
    """
