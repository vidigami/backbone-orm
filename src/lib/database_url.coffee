###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
URL = require 'url'

BackboneORM = require '../core'

SUPPORTED_KEYS = ['protocol', 'slashes', 'auth', 'host', 'hostname', 'port', 'search', 'query', 'hash', 'href']

module.exports = class DatabaseURL

  # Create an instance. Arguments follow the convention of node url
  constructor: (url, parse_query_string, slashes_denote_host) ->
    url_parts = URL.parse(url, parse_query_string, slashes_denote_host)

    # multiple, comma-delimited databases
    parts = url_parts.pathname.split(',')
    if parts.length > 1
      start_parts = _.pick(url_parts, 'protocol', 'auth', 'slashes')
      start_parts.host = '{1}'; start_parts.pathname = '{2}'
      start_url = URL.format(start_parts)
      start_url = start_url.replace('{1}/{2}', '')

      path_paths = url_parts.pathname.split('/')
      url_parts.pathname = "/#{path_paths[path_paths.length-2]}/#{path_paths[path_paths.length-1]}"

      databases_string = url.replace(start_url, '')
      databases_string = databases_string.substring(0, databases_string.indexOf(url_parts.pathname))
      databases = databases_string.split(',')

      delete url_parts[key] for key in ['host', 'hostname', 'port']
      @hosts = []
      for database in databases
        host = database.split(':')
        @hosts.push if host.length is 1 then {host: host[0], hostname: host[0]} else {host: host[0], hostname: "#{host[0]}:#{host[1]}", port: host[1]}

    database_parts = _.compact(url_parts.pathname.split('/'))
    @table = database_parts.pop()
    @database = database_parts.join('/')
    @[key] = url_parts[key] for key in SUPPORTED_KEYS when url_parts.hasOwnProperty(key)

  format: (options={}) ->
    url_parts = _.pick(@, SUPPORTED_KEYS)
    url_parts.pathname = ''

    # array of hosts
    if @hosts
      host_strings = _.map(@hosts, (host) -> "#{host.host}#{if host.port then ':' + host.port else ''}")
      url_parts.pathname += host_strings.join(',')
      url_parts.host = "{1}"

    url_parts.pathname += "/#{@database}" if @database
    url_parts.pathname += "/#{@table}" if @table and not options.exclude_table
    (delete url_parts.search; delete url_parts.query) if options.exclude_search or options.exclude_query
    url = URL.format(url_parts)
    url = url.replace("{1}/#{url_parts.pathname}", url_parts.pathname) if @hosts
    return url

  parseAuth: ->
    return null unless @auth
    auth_parts = @auth.split(':')
    result = {user: auth_parts[0]}
    result.password = if auth_parts.length > 1 then auth_parts[1] else null
    return result

  modelName: ->
    return if @table then BackboneORM.naming_conventions.modelName(@table, false) else null
