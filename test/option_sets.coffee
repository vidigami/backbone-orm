_ = require 'underscore'
powerset = require 'powerset'

ARG_OPTIONS =
  all: '-a'
  none: '-n'
  cache: '-c'
  embed: '-e'
OPTION_KEYS = _.without(_.keys(ARG_OPTIONS), 'all', 'none')

options = {}
if process?
  args = process.argv.slice(2)
  options[key] = value in args for key, value of ARG_OPTIONS

arrayToOptions = (keys) -> results = {}; results[key] = (key in keys) for key in OPTION_KEYS; return results

# constructs a string to be used in describe https://github.com/visionmedia/mocha/wiki/Tagging
getTags = (options) -> tags = []; tags.push("@#{option_key}") for option_key in OPTION_KEYS when options[option_key]; return if tags.length then tags.join(' ') else '@no_options'

options.all or= _.every(['none'].concat(OPTION_KEYS), (key) -> not options[key])
exports = if options.all then _.map(powerset(OPTION_KEYS), arrayToOptions) else [options]
option_set.$tags = getTags(option_set) for option_set in exports

(if window? then window else if global? then global).option_sets = exports; module?.exports = exports
