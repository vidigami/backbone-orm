###
  backbone-orm.js 0.7.9
  Copyright (c) 2013-2014 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

_ = require 'underscore'
Queue = require './queue'

SPLIT = false

# @nodoc
safeStackCall = (fn, callback) =>
  caller = new Queue()
  caller.defer (callback) -> fn(callback)
  caller.await callback

module.exports = class IterationUtils
  @MAX_ITERATION_COUNT: 500

  # @nodoc
  @nextTick: process?.nextTick or _.defer

  ##############################
  # Iterating
  ##############################

  # @nodoc
  @each: (array, iterator, callback) =>
    return callback() unless count = array.length
    index = 0

    if SPLIT
      queue = new Queue(1)
      for start_index in [0..count] by IterationUtils.MAX_ITERATION_COUNT
        do (start_index) => queue.defer (callback) ->
          iteration_end = Math.min(start_index+IterationUtils.MAX_ITERATION_COUNT, count)
          next = (err) =>
            return callback(err) if err or (index >= iteration_end)
            iterator(array[index++], next)
          next()
      queue.await callback
    else
      safeStackCall ((callback) ->
        iterate = -> iterator array[index++], (err) ->
          return callback(err) if err or (index >= count)
          if index and (index % IterationUtils.MAX_ITERATION_COUNT is 0) then IterationUtils.nextTick(iterate) else iterate()
        iterate()
      ), callback

  # @nodoc
  @popEach: (array, iterator, callback) =>
    return callback() unless count = array.length
    index = 0

    if SPLIT
      queue = new Queue(1)
      for start_index in [0..count] by IterationUtils.MAX_ITERATION_COUNT
        do (start_index) => queue.defer (callback) ->
          iteration_end = Math.min(start_index+IterationUtils.MAX_ITERATION_COUNT, count)
          next = (err) =>
            return callback(err) if err or (index >= iteration_end) or (array.length is 0)
            index++; iterator(array.pop(), next)
          next()
      queue.await callback
    else
      safeStackCall ((callback) ->
        iterate = -> index++; iterator array.pop(), (err) ->
          return callback(err) if err or (index >= count) or (array.length is 0)
          if index and (index % IterationUtils.MAX_ITERATION_COUNT is 0) then IterationUtils.nextTick(iterate) else iterate()
        iterate()
      ), callback
