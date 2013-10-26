
args = process.argv.slice(2)
options =
  none: '-n' in args
  cache: '-c' in args
  query_cache: '-q' in args
  embed: '-e' in args
  all: '-a' in args
options.all or= (not options.cache and not options.query_cache and not options.embed and not options.none)

OPTIONS = ['cache', 'query_cache', 'embed']
gen = (keys) ->
  results = {}
  results[key] = true for key in keys
  return results

combos = (array) ->
  results = [{}]
  results.push(gen([key])) for key in array # start with single keys
  while array.length
    keys = [array.pop()]
    (keys.push(item); results.push(gen(keys))) for item in array
  return results

module.exports = if options.all then combos(OPTIONS) else [options]
