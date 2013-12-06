fs = require 'fs'
path = require 'path'

module.exports =

  license: """
    /*
      backbone-orm.js 0.5.4
      Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
      License: MIT (http://www.opensource.org/licenses/mit-license.php)
      Dependencies: Backbone.js, Underscore.js, Moment.js, and Inflection.js.
    */
    """

  start: fs.readFileSync(path.join(__dirname, 'require.js'), {encoding: 'utf8'})

  end: """
  if (typeof exports == 'object') {
    module.exports = require('backbone-orm/lib/index');
  } else if (typeof define == 'function' && define.amd) {
    define(['require', 'underscore', 'backbone', 'moment', 'inflection'], function(){ return require('backbone-orm/lib/index'); });
  } else {
    this.BackboneORM = require('backbone-orm/lib/index');
  }
}).call(this);
    """
