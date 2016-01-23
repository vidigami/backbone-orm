###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

try stream = require 'stream' # stream is large so it is optional on the browser
if stream?.Readable
  # @nodoc
  module.exports = class ModelStream extends stream.Readable
    constructor: (@model_type, @query={}) -> super {objectMode: true}
    _read: ->
      return if @ended or @started
      @started = true
      done = (err) => @ended = true; @emit('error', err) if err; @push(null)
      @model_type.each @query, ((model, callback) => @push(model); callback()), done
