###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

# TODO: handle double callbacks, to provide promise-like guarantees
module.exports = class Queue
  constructor: (@parallelism) ->
    @parallelism or= Infinity
    @tasks = []; @running_count = 0; @error = null
    @await_callback = null

  defer: (callback) -> @tasks.push(callback); @_runTasks()

  await: (callback) ->
    throw new Error "Awaiting callback was added twice: #{callback}" if @await_callback
    @await_callback = callback
    @_callAwaiting() if @error or not (@tasks.length + @running_count)

  # @nodoc
  _doneTask: (err) => @running_count--; @error or= err; @_runTasks()

  # @nodoc
  _runTasks: ->
    return @_callAwaiting() if @error or not (@tasks.length + @running_count)

    while @running_count < @parallelism
      return unless @tasks.length
      current = @tasks.shift(); @running_count++
      current(@_doneTask)

  # @nodoc
  _callAwaiting: ->
    return if @await_called or not @await_callback
    @await_called = true; @await_callback(@error)
