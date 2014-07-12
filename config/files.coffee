wrench = require 'wrench'
path = require 'path'
fs = require 'fs'

# TODO: determine if browser tests should always use bower versions, or if npm versions are fine
try bower_dir = fs.readdirSync('bower_components')
# remember, order matters for these browser dependancies
if bower_dir?.length
  local_dependencies = ['./bower_components/underscore/underscore.js', './bower_components/backbone/backbone.js', './bower_components/moment/moment.js']
else
  local_dependencies = (path.relative('.', require.resolve(module_name)) for module_name in ['underscore', 'backbone', 'moment'])
local_dependencies.push('./stream.js')

module.exports =
  local_dependencies: local_dependencies

  test_parameters: './test/parameters.coffee'
  tests_webpack: ("./config/builds/test/#{filename}" for filename in wrench.readdirSyncRecursive(__dirname + '/builds/test') when /\.webpack.config.coffee$/.test(filename))
  tests_browser: ("./test/spec/sync/#{filename}" for filename in wrench.readdirSyncRecursive(__dirname + '/../test/spec/sync') when /\.coffee$/.test(filename))
