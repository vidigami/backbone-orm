
/*
  backbone-orm.js 0.5.17
  Copyright (c) 2013 Vidigami - https://github.com/vidigami/backbone-orm
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
 */
var DatabaseURL, SUPPORTED_KEYS, URL, inflection, _;

_ = require('underscore');

inflection = require('inflection');

URL = require('url');

SUPPORTED_KEYS = ['protocol', 'slashes', 'auth', 'host', 'hostname', 'port', 'search', 'query', 'hash', 'href'];

module.exports = DatabaseURL = (function() {
  function DatabaseURL(url, parse_query_string, slashes_denote_host) {
    var database, database_parts, databases, databases_string, host, key, parts, path_paths, start_parts, start_url, url_parts, _i, _j, _k, _len, _len1, _len2, _ref;
    url_parts = URL.parse(url, parse_query_string, slashes_denote_host);
    parts = url_parts.pathname.split(',');
    if (parts.length > 1) {
      start_parts = _.pick(url_parts, 'protocol', 'auth', 'slashes');
      start_parts.host = '{1}';
      start_parts.pathname = '{2}';
      start_url = URL.format(start_parts);
      start_url = start_url.replace('{1}/{2}', '');
      path_paths = url_parts.pathname.split('/');
      url_parts.pathname = "/" + path_paths[path_paths.length - 2] + "/" + path_paths[path_paths.length - 1];
      databases_string = url.replace(start_url, '');
      databases_string = databases_string.substring(0, databases_string.indexOf(url_parts.pathname));
      databases = databases_string.split(',');
      _ref = ['host', 'hostname', 'port'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        delete url_parts[key];
      }
      this.hosts = [];
      for (_j = 0, _len1 = databases.length; _j < _len1; _j++) {
        database = databases[_j];
        host = database.split(':');
        this.hosts.push(host.length === 1 ? {
          host: host[0],
          hostname: host[0]
        } : {
          host: host[0],
          hostname: "" + host[0] + ":" + host[1],
          port: host[1]
        });
      }
    }
    database_parts = url_parts.pathname.split('/');
    this.table = database_parts.pop();
    this.database = database_parts[database_parts.length - 1];
    for (_k = 0, _len2 = SUPPORTED_KEYS.length; _k < _len2; _k++) {
      key = SUPPORTED_KEYS[_k];
      if (url_parts.hasOwnProperty(key)) {
        this[key] = url_parts[key];
      }
    }
  }

  DatabaseURL.prototype.format = function(options) {
    var host_strings, url, url_parts;
    if (options == null) {
      options = {};
    }
    url_parts = _.pick(this, SUPPORTED_KEYS);
    url_parts.pathname = '';
    if (this.hosts) {
      host_strings = _.map(this.hosts, function(host) {
        return "" + host.host + (host.port ? ':' + host.port : '');
      });
      url_parts.pathname += host_strings.join(',');
      url_parts.host = "{1}";
    }
    if (this.database) {
      url_parts.pathname += "/" + this.database;
    }
    if (this.table && !options.exclude_table) {
      url_parts.pathname += "/" + this.table;
    }
    if (options.exclude_search || options.exclude_query) {
      delete url_parts.search;
      delete url_parts.query;
    }
    url = URL.format(url_parts);
    if (this.hosts) {
      url = url.replace("{1}/" + url_parts.pathname, url_parts.pathname);
    }
    return url;
  };

  DatabaseURL.prototype.parseAuth = function() {
    var auth_parts, result;
    if (!this.auth) {
      return null;
    }
    auth_parts = this.auth.split(':');
    result = {
      user: auth_parts[0]
    };
    result.password = auth_parts.length > 1 ? auth_parts[1] : null;
    return result;
  };

  DatabaseURL.prototype.modelName = function() {
    if (this.table) {
      return inflection.classify(inflection.singularize(this.table));
    } else {
      return null;
    }
  };

  return DatabaseURL;

})();
