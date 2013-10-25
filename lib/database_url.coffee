_ = require 'underscore'
inflection = require 'inflection'
URL = require '../vendor/url'

SUPPORTED_KEYS = ['protocol', 'slashes', 'auth', 'host', 'hostname', 'port', 'search', 'query', 'hash', 'href']

module.exports = class DatabaseURL

  # follow the convention of node url
  constructor: (url, parse_query_string, slashes_denote_host) ->
    url_parts = URL.parse(url, parse_query_string, slashes_denote_host)
    database_parts = url_parts.pathname.split('/')
    @table = database_parts.pop()
    @model_name = inflection.classify(inflection.singularize(@table))
    @database = database_parts[database_parts.length-1]
    @[key] = url_parts[key] for key in SUPPORTED_KEYS when url_parts.hasOwnProperty(key)

  format: (options={}) ->
    url_parts = _.pick(@, SUPPORTED_KEYS)
    url_parts.pathname = ''
    url_parts.pathname += "/#{@database}" if @database
    url_parts.pathname += "/#{@table}" if @table and not options.exclude_table
    return URL.format(url_parts)

  parseAuth: ->
    return null unless @auth
    auth_parts = url_parts.auth.split(':')
    result = {user: auth_parts[0]}
    result.password = if auth_parts.length > 1 then auth_parts[1] else null
    return result
