_ = require 'underscore'
Queue = require 'queue-async'

option_sets = require('./option_sets')

runTests = (options, callback) ->
  console.log "\nBackbone ORM: Running tests:\n", options
  queue = new Queue(1)
  queue.defer (callback) -> require('./unit/all_generators')(options, callback)
  queue.defer (callback) -> require('./unit/fabricator')(options, callback)
  queue.await (err) -> console.log "\nBackbone ORM: Completed tests:", options; callback()

queue = new Queue(1)
for options in option_sets
  do (options) -> queue.defer (callback) -> runTests(options, callback)

queue.await (err) -> console.log "\nAll test combinations completed"
