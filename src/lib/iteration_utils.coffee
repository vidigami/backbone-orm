###
  backbone-orm.js 0.7.9
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
Queue = require './queue'

# @nodoc
nextTick = process?.nextTick or _.defer

module.exports = class IterationUtils
  @MAX_ITERATION_COUNT: 500

  ##############################
  # Iterating
  ##############################

  # @nodoc
  @eachDone: (array, iterator, callback) =>
    return callback() unless count = array.length

    index = 0
    queue = new Queue()
    queue.defer (callback) ->
      iterate = -> iterator array[index++], (err, done) ->
        return callback(err) if err or (index >= count) or done
        if index and (index % IterationUtils.MAX_ITERATION_COUNT is 0) then nextTick(iterate) else iterate()
      iterate()
    queue.await callback

  # @nodoc
  @each: (array, iterator, callback) =>
    return callback() unless count = array.length

    index = 0
    queue = new Queue()
    queue.defer (callback) ->
      iterate = -> iterator array[index++], (err) ->
        return callback(err) if err or (index >= count)
        if index and (index % IterationUtils.MAX_ITERATION_COUNT is 0) then nextTick(iterate) else iterate()
      iterate()
    queue.await callback

  # @nodoc
  @popEach: (array, iterator, callback) =>
    return callback() unless count = array.length

    index = 0
    queue = new Queue()
    queue.defer (callback) ->
      iterate = -> index++; iterator array.pop(), (err) ->
        return callback(err) if err or (index >= count) or (array.length is 0)
        if index and (index % IterationUtils.MAX_ITERATION_COUNT is 0) then nextTick(iterate) else iterate()
      iterate()
    queue.await callback
