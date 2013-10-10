
args = process.argv.slice(2)
options =
  none: '-n' in args
  cache: '-c' in args
  query_cache: '-q' in args
  embed: '-e' in args
  all: '-a' in args
options.all or= (not options.cache and not options.query_cache and not options.embed and not options.none)

option_sets = []
if options.all
  option_sets.push({})

  option_sets.push({cache: true})
  option_sets.push({query_cache: true})
  option_sets.push({embed: true})

  option_sets.push({cache: true, query_cache: true})
  option_sets.push({cache: true, embed: true})
  option_sets.push({query_cache: true, embed: true})

  option_sets.push({cache: true, query_cache: true, embed: true})
else
  option_sets = [options]

module.exports = option_sets
