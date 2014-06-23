###
  backbone-orm.js 0.5.16
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
###

# stream is large so it is optional on the browser
try stream = require('stream') catch e
(module.exports = null; return) unless stream?.Readable

# @nodoc
module.exports = class ModelStream extends stream.Readable
  constructor: (@model_type, @query={}) -> super {objectMode: true}
  _read: ->
    return if @ended or @started
    @started = true
    done = (err) => @ended = true; @emit('error', err) if err; @push(null)
    @model_type.each @query, ((model, callback) => @push(model); callback()), done
