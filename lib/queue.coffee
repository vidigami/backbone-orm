#module.exports = class Queue
class Queue
  constructor: ->
    @deferred_callbacks = []
    @awaiting_callbacks = []
    @error = @current = null

  defer: (callback) ->
    return @_callAwaiting() if @error # in an error state

    @deferred_callbacks.push(callback)
    @_next() unless @current

  await: (callback) ->
    @awaiting_callbacks.push(callback)
    return @_callAwaiting() if @error or not @deferred_callbacks.length

  _next: (err) =>
    @current = null
    return @_callAwaiting() if @error or not @deferred_callbacks.length

    @current = @deferred_callbacks.shift()
    @current(@_next)

  _callAwaiting: ->
    awaiting = @awaiting_callbacks.splice(0)
    callback(@error) for callback in awaiting

module.exports = require 'queue-async'
