_ = require 'underscore'

ARG_OPTIONS =
  all: '-a'
  none: '-n'
  cache: '-c'
  query_cache: '-q'
  embed: '-e'
OPTION_KEYS = _.without(_.keys(ARG_OPTIONS), 'all', 'none')

args = process.argv.slice(2)
options = {}; options[key] = value in args for key, value of ARG_OPTIONS

gen = (keys) -> results = {}; results[key] = (key in keys) for key in OPTION_KEYS; return results

combos = (array) ->
  results = [gen([])]
  results.push(gen([key])) for key in array # start with single keys
  array = _.clone(array)
  while array.length
    keys = [array.pop()]
    results.push(gen(keys = keys.concat([item]))) for item in array
  return results

options.all or= _.every(['none'].concat(OPTION_KEYS), (key) -> not options[key])
module.exports = if options.all then combos(OPTION_KEYS) else [options]
