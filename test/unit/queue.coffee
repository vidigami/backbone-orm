assert = require 'assert'

Queue = require '../../lib/queue'

runTests = (options, callback) ->

  describe 'Queue', ->

    before (done) -> return done() unless options.before; options.before([], done)
    after (done) -> callback(); done()

    it 'parallelism 1', (done) ->
      done()

module.exports = (options, callback) ->
  runTests(options, callback)
