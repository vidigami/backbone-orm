Queue = require 'queue-async'

queue = new Queue(1)
queue.defer (callback) -> require('./unit/cursor')({}, callback) # TODO
queue.defer (callback) -> require('./unit/cache')({}, callback) # TODO
queue.defer (callback) -> require('./unit/fabricator')({}, callback)
queue.defer (callback) -> require('./unit/all_generators')({}, callback)
queue.await (err) -> console.log "Backbone ORM: Completed tests"
