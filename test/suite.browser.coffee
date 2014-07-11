BackboneORM = window?.BackboneORM or require?('backbone-orm')
_ = BackboneORM._

# load global
test_parameters = require './parameters'

# use tags to grep out certain option sets https://github.com/visionmedia/mocha/wiki/Tagging
describe 'backbone-orm', ->
  require('./spec/collection/sync')
  require('./spec/compatibility/events')
  require('./spec/conventions/callbacks')
  require('./spec/conventions/many')
  require('./spec/conventions/one')
  require('./spec/flat/batch')
  require('./spec/flat/convenience')
  require('./spec/flat/cursor')
  require('./spec/flat/find')
  require('./spec/flat/page')
  require('./spec/flat/sort')
  require('./spec/flat/sync')
  require('./spec/iteration/each')
  require('./spec/iteration/interval')
  require('./spec/iteration/stream')
