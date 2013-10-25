assert = require 'assert'

URL = require '../../vendor/url'
_ = require 'underscore'

runTests = (options, callback) ->

  describe 'URL', ->

    before (done) -> return done() unless options.before; options.before([], done)
    after (done) -> callback(); done()

    it 'infinite parallelism', (done) ->
      queue = new Queue()

      results = []
      queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback()), 1*10
      queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback()), 2*10
      queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*10
      queue.await (err) ->
        assert.ok(!err, "No errors: #{err}")
        assert.deepEqual(results, ['1.0', '2.0', '3.0', '1.1', '2.1', '3.1'])
        done()

module.exports = (options, callback) ->
  runTests(options, callback)
