util = require 'util'
assert = require 'assert'
_ = require 'underscore'
moment = require 'moment'

Fabricator = require '../../fabricator'
MockServerModel = require '../../mocks/server_model'

describe 'Fabricator', ->

  describe 'value', ->

    it 'generate undefined', (done) ->
      VALUE = undefined
      gen = Fabricator.value
      assert.equal(gen(), VALUE)
      assert.equal(gen(), VALUE)
      assert.equal(gen(), VALUE)
      done()

    it 'generate integers', (done) ->
      VALUE = 29029
      gen = Fabricator.value(VALUE)

      assert.equal(gen(), VALUE)
      assert.equal(gen(), VALUE)
      assert.equal(gen(), VALUE)
      done()

    it 'generate strings', (done) ->
      VALUE = 'value1'
      gen = Fabricator.value(VALUE)

      assert.equal(gen(), VALUE)
      assert.equal(gen(), VALUE)
      assert.equal(gen(), VALUE)
      done()

    it 'generate dates', (done) ->
      VALUE = new Date()
      gen = Fabricator.value(VALUE)

      assert.equal(gen().valueOf(), VALUE.valueOf())
      assert.equal(gen().valueOf(), VALUE.valueOf())
      assert.equal(gen().valueOf(), VALUE.valueOf())
      done()

  describe 'uniqueId', ->

    it 'just numbers', (done) ->
      gen = Fabricator.uniqueId
      values = (gen() for x in [0..10])
      uniq_values = _.uniq(values)

      assert.equal(values.length, uniq_values.length, "Actual: #{util.inspect(values)}. Expected: #{util.inspect(uniq_values)}")
      done()

    gen = (fn) ->
      it "with string (#{fn})", (done) ->
        VALUE = 'name_'
        gen = Fabricator[fn](VALUE)
        values = (gen() for x in [0..10])
        uniq_values = _.uniq(values)

        assert.equal(values.length, uniq_values.length, "Actual: #{util.inspect(values)}. Expected: #{util.inspect(uniq_values)}")
        assert.ok(_.every(values, (value) -> value.substring(0, VALUE.length) is VALUE), 'All start with expected value')
        done()

    gen('uniqueId')
    gen('uniqueString')

  describe 'date', ->

    it 'generate now', (done) ->
      gen = Fabricator.date
      assert.ok(gen().valueOf() < (new Date()).valueOf())
      assert.ok(gen().valueOf() < (new Date()).valueOf())
      assert.ok(gen().valueOf() < (new Date()).valueOf())
      done()

    it 'generate dates in steps (ms)', (done) ->
      STEP = 100
      gen = Fabricator.date(STEP)
      START = gen()

      assert.equal(gen().valueOf() - START.valueOf(), 1*STEP)
      assert.equal(gen().valueOf() - START.valueOf(), 2*STEP)
      assert.equal(gen().valueOf() - START.valueOf(), 3*STEP)
      done()

    it 'generate dates in steps (ms) with start', (done) ->
      STEP = 100
      START = moment().add('days', 1).add('minutes', 10).toDate()
      gen = Fabricator.date(START, STEP)

      assert.equal(gen().valueOf() - START.valueOf(), 0*STEP)
      assert.equal(gen().valueOf() - START.valueOf(), 1*STEP)
      assert.equal(gen().valueOf() - START.valueOf(), 2*STEP)
      assert.equal(gen().valueOf() - START.valueOf(), 3*STEP)
      done()


