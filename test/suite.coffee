Queue = require 'queue-async'

args = process.argv.slice(2)
console.log 'ARGS', args, '-c' in args
options =
  cache: '-c' in args
  query_cache: '-q' in args
  embed: '-e' in args
  all: '-a' in args
  none: '-n' in args

runTests = (options, callback) ->
  queue = new Queue(1)
  queue.defer (callback) -> require('./unit/all_generators')(options, callback)
  queue.defer (callback) -> require('./unit/fabricator')(options, callback)
  queue.await (err) -> console.log "\nBackbone ORM: Completed tests:", options; callback()

if options.all or (not options.cache and not options.query_cache and not options.embed and not options.none)
  queue = new Queue(1)
  queue.defer (callback) -> runTests({}, callback)

  queue.defer (callback) -> runTests({cache: true}, callback)
  queue.defer (callback) -> runTests({query_cache: true}, callback)
  queue.defer (callback) -> runTests({embed: true}, callback)

  queue.defer (callback) -> runTests({cache: true, query_cache: true}, callback)
  queue.defer (callback) -> runTests({cache: true, embed: true}, callback)
  queue.defer (callback) -> runTests({query_cache: true, embed: true}, callback)

  queue.defer (callback) -> runTests({cache: true, query_cache: true, embed: true}, callback)

  queue.await (err) -> console.log "\nAll test combinations completed"

else
  runTests(options, -> console.log "\nAll test combinations completed")
