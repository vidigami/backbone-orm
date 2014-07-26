assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, Queue} = BackboneORM

describe 'Queue @quick', ->
  it 'infinite parallelism', (done) ->
    queue = new Queue()

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback()), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback()), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(!err, "No errors: #{err}")
      assert.deepEqual(results, ['1.0', '2.0', '3.0', '1.1', '2.1', '3.1'])
      done()

  it 'infinite parallelism (errors 1)', (done) ->
    queue = new Queue()

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback(new Error('error'))), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback()), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(err, "Has error: #{err}")
      assert.deepEqual(results, ['1.0', '2.0', '3.0', '1.1'])
      done()

  it 'infinite parallelism (errors 2)', (done) ->
    queue = new Queue()

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback()), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback(new Error('error'))), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(err, "Has error: #{err}")
      assert.deepEqual(results, ['1.0', '2.0', '3.0', '1.1', '2.1'])
      done()

  it 'parallelism 1', (done) ->
    queue = new Queue(1)

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback()), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback()), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(!err, "No errors: #{err}")
      assert.deepEqual(results, ['1.0', '1.1', '2.0', '2.1', '3.0', '3.1'])
      done()

  it 'parallelism 1 (errors 1)', (done) ->
    queue = new Queue(1)

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback(new Error('error'))), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback()), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(err, "Has error: #{err}")
      assert.deepEqual(results, ['1.0', '1.1'])
      done()

  it 'parallelism 1 (errors 2)', (done) ->
    queue = new Queue(1)

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback()), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback(new Error('error'))), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(err, "Has error: #{err}")
      assert.deepEqual(results, ['1.0', '1.1', '2.0', '2.1'])
      done()

  it 'parallelism 2', (done) ->
    queue = new Queue(2)

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback()), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback()), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(!err, "No errors: #{err}")
      assert.deepEqual(results, ['1.0', '2.0', '1.1', '3.0', '2.1', '3.1'])
      done()

  it 'parallelism 2 (errors 1)', (done) ->
    queue = new Queue(2)

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback(new Error('error'))), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback()), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(err, "Has error: #{err}")
      assert.deepEqual(results, ['1.0', '2.0', '1.1'])
      done()

  it 'parallelism 2 (errors 2)', (done) ->
    queue = new Queue(2)

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback()), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback(new Error('error'))), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(err, "Has error: #{err}")
      assert.deepEqual(results, ['1.0', '2.0', '1.1', '3.0', '2.1'])
      done()

  it 'catches await added twice', (done) ->
    queue = new Queue(1)

    results = []
    queue.defer (callback) -> results.push('1.0'); _.delay (-> results.push('1.1'); callback()), 1*20
    queue.defer (callback) -> results.push('2.0'); _.delay (-> results.push('2.1'); callback(new Error('error'))), 2*20
    queue.defer (callback) -> results.push('3.0'); _.delay (-> results.push('3.1'); callback()), 3*20
    queue.await (err) ->
      assert.ok(err, "Has error: #{err}")
      assert.deepEqual(results, ['1.0', '1.1', '2.0', '2.1'])
      done()
    try
      queue.await (err) ->
    catch err
      assert.ok(err, "Has error: #{err}")
      assert.ok(err.toString().indexOf('Error: Awaiting callback was added twice') is 0, 'Expected message')

  it 'calls await if an error occurs before it is added', (done) ->
    queue = new Queue(1)

    results = []
    queue.defer (callback) -> results.push('1.0'); callback(new Error('error'))
    queue.defer (callback) -> results.push('2.0'); callback()
    queue.defer (callback) -> results.push('3.0'); callback()
    queue.await (err) ->
      assert.ok(err, "Has error: #{err}")
      assert.deepEqual(results, ['1.0'])
      done()
