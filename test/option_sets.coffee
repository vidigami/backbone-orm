_ = require 'underscore'
powerset = require 'powerset'

ARG_OPTIONS =
  all: '-a'
  none: '-n'
  cache: '-c'
  embed: '-e'
OPTION_KEYS = _.without(_.keys(ARG_OPTIONS), 'all', 'none')

args = process.argv.slice(2)
options = {}; options[key] = value in args for key, value of ARG_OPTIONS

arrayToOptions = (keys) -> results = {}; results[key] = (key in keys) for key in OPTION_KEYS; return results

options.all or= _.every(['none'].concat(OPTION_KEYS), (key) -> not options[key])
module.exports = if options.all then _.map(powerset(OPTION_KEYS), arrayToOptions) else [options]
