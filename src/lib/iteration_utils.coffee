###
  backbone-orm.js 0.7.14
  Copyright (c) 2013-2016 Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
###

# @nodoc
nextTick = process?.nextTick or (require 'underscore').defer

module.exports = class IterationUtils
  @MAX_ITERATION_COUNT: 300

  ##############################
  # Iterating
  ##############################

  # @nodoc
  @eachDone: (array, iterator, callback) =>
    return callback() unless count = array.length

    index = 0
    iterate = -> iterator array[index++], (err, done) ->
      return callback(err) if err or (index >= count) or done
      if index and (index % IterationUtils.MAX_ITERATION_COUNT is 0) then nextTick(iterate) else iterate()
    iterate()

  # @nodoc
  @each: (array, iterator, callback) =>
    return callback() unless count = array.length

    index = 0
    iterate = -> iterator array[index++], (err) ->
      return callback(err) if err or (index >= count)
      if index and (index % IterationUtils.MAX_ITERATION_COUNT is 0) then nextTick(iterate) else iterate()
    iterate()

  # @nodoc
  @popEach: (array, iterator, callback) =>
    return callback() unless count = array.length

    index = 0
    iterate = -> index++; iterator array.pop(), (err) ->
      return callback(err) if err or (index >= count) or (array.length is 0)
      if index and (index % IterationUtils.MAX_ITERATION_COUNT is 0) then nextTick(iterate) else iterate()
    iterate()
