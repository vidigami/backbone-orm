assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Backbone, Queue, Utils, JSONUtils, Fabricator} = BackboneORM

describe 'Fabricator @quick', ->
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

      assert.equal(gen().getTime(), VALUE.getTime())
      assert.equal(gen().getTime(), VALUE.getTime())
      assert.equal(gen().getTime(), VALUE.getTime())
      done()

  describe 'uniqueId', ->

    it 'just numbers', (done) ->
      gen = Fabricator.uniqueId
      values = (gen() for x in [0..10])
      uniq_values = _.uniq(values)

      # assert.equal(values.length, uniq_values.length, "Actual: #{JSONUtils.stringify(values)}. Expected: #{JSONUtils.stringify(uniq_values)}")
      done()

    gen = (fn) ->
      it "with string (#{fn})", (done) ->
        VALUE = 'name_'
        gen = Fabricator[fn](VALUE)
        values = (gen() for x in [0..10])
        uniq_values = _.uniq(values)

        assert.equal(values.length, uniq_values.length, "Actual: #{JSONUtils.stringify(values)}. Expected: #{JSONUtils.stringify(uniq_values)}")
        assert.ok(_.every(values, (value) -> value.substring(0, VALUE.length) is VALUE), 'All start with expected value')
        done()

    gen('uniqueId')
    gen('uniqueString')

  describe 'date', ->

    it 'generate now', (done) ->
      gen = Fabricator.date

      assert.ok(gen().getTime() <= (new Date()).getTime())
      assert.ok(gen().getTime() <= (new Date()).getTime())
      assert.ok(gen().getTime() <= (new Date()).getTime())
      done()

    it 'generate dates in steps (ms)', (done) ->
      STEP = 100
      gen = Fabricator.date(STEP)
      START = gen()

      assert.equal(gen().getTime() - START.getTime(), 1*STEP)
      assert.equal(gen().getTime() - START.getTime(), 2*STEP)
      assert.equal(gen().getTime() - START.getTime(), 3*STEP)
      done()

    it 'generate dates in steps (ms) with start', (done) ->
      STEP = 100
      START = new Date(); START.setDate(START.getDate(), + 1)
      gen = Fabricator.date(START, STEP)

      assert.equal(gen().getTime() - START.getTime(), 0*STEP)
      assert.equal(gen().getTime() - START.getTime(), 1*STEP)
      assert.equal(gen().getTime() - START.getTime(), 2*STEP)
      assert.equal(gen().getTime() - START.getTime(), 3*STEP)
      done()
