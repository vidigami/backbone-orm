_ = require 'underscore'
Queue = require '../lib/queue'

#ModelTypeID = require('../lib/cache/singletons').ModelTypeID # returns undefined
#ModelTypeID.strict = false

option_sets = require('./option_sets')
# option_sets = option_sets.slice(0, 1)

queue = new Queue(1)
for options in option_sets
  do (options) -> queue.defer (callback) ->
    console.log "\nBackbone ORM: Running tests: ", options
    test_queue = new Queue(1)

    # not working on web - tries to run stuff from /node
#    test_queue.defer (callback) -> require('./unit/all_generators')(options, callback)

    # runs no tests on web - why ?
    #test_queue.defer (callback) -> require('./unit/cursor')(options, callback)

    # these babies work
    test_queue.defer (callback) -> require('./unit/fabricator')(options, callback)
    test_queue.defer (callback) -> require('./unit/queue')(options, callback)
    test_queue.defer (callback) -> require('./unit/url')(options, callback)
    test_queue.await (err) -> console.log "\nBackbone ORM: Completed tests:", options; callback()

queue.await (err) -> console.log "\nAll test combinations completed"