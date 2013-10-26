_ = require 'underscore'

OPTIONS =
  all: '-a'
  none: '-n'
  cache: '-c'
  query_cache: '-q'
  embed: '-e'

args = process.argv.slice(2)

options = {}; options[key] = value in args for key, value of OPTIONS
options_keys = _.keys(OPTIONS)

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

options.all or= _.every(_.without(options_keys, 'all'), (key) -> not options[key])
module.exports = if options.all then combos(_.without(options_keys, 'all', 'none')) else [options]

console.log module.exports
