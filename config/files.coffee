wrench = require 'wrench'
path = require 'path'
fs = require 'fs'

# TODO: determine if browser tests should always use bower versions, or if npm versions are fine
try bower_dir = fs.readdirSync('bower_components')
# remember, order matters for these browser dependancies
if bower_dir?.length
  local_dependancies = ['./bower_components/underscore/underscore.js', './bower_components/backbone/backbone.js', './bower_components/moment/moment.js']
else
  local_dependancies = (path.relative('.', require.resolve(module_name)) for module_name in ['underscore', 'backbone', 'moment'])
local_dependancies.push('./stream.js')

module.exports =
  local_dependancies: local_dependancies

  test_parameters: './test/parameters.coffee'
  tests_core: ("./test/spec/#{filename}" for filename in wrench.readdirSyncRecursive('./test/spec') when /\.coffee$/.test(filename))
  tests_webpack: ("./config/builds/test/#{filename}" for filename in wrench.readdirSyncRecursive('./config/builds/test') when /\.webpack.config.coffee$/.test(filename))
