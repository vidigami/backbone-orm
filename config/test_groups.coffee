fs = require 'fs'
path = require 'path'
_ = require 'underscore'
gutil = require 'gulp-util'
FILES = require './files'

module.exports = TEST_GROUPS = {}

###############################
# Browser Globals
###############################
LIBRARIES =
  backbone_underscore: (path.relative('.', require.resolve(module_name)) for module_name in ['jquery', 'underscore', 'backbone', 'moment']).concat('./backbone-orm.js')
  backbone_underscore_min: (path.relative('.', require.resolve(module_name)) for module_name in ['jquery', 'underscore', 'backbone', 'moment']).concat('./backbone-orm.min.js')
  backbone_lodash: (path.relative('.', require.resolve(module_name)) for module_name in ['jquery', 'lodash', 'backbone', 'moment']).concat('./backbone-orm.js')
  backbone_lodash_min: (path.relative('.', require.resolve(module_name)) for module_name in ['jquery', 'lodash', 'backbone', 'moment']).concat('./backbone-orm.min.js')

TEST_GROUPS.browser_globals = []
for library_name, library_files of LIBRARIES
  TEST_GROUPS.browser_globals.push({name: "browser_globals_#{library_name}", files: library_files.concat(['./_temp/parameters.js', './_temp/option_sets.js', './test/spec/lib/**/*.tests.coffee', './test/spec/sync/**/*.tests.coffee'])})

###############################
# AMD
###############################
AMD_OPTIONS = require './amd/gulp-options'
TEST_GROUPS.amd = []
for test in TEST_GROUPS.browser_globals when (test.name.indexOf('_min') < 0 and test.name.indexOf('legacy_') < 0 and test.name.indexOf('parse_') < 0)
  test_files = ['./node_modules/chai/chai.js', './stream.js'].concat(test.files); files = []; test_patterns = []; path_files = []
  files.push({pattern: './test/lib/requirejs-2.1.14.js'})
  for file in test_files
    (test_patterns.push(file); continue) if file.indexOf('.tests.') >= 0
    files.push({pattern: file, included: false})
    path_files.push(file)
  files.push("_temp/amd/#{test.name}/**/*.js")
  TEST_GROUPS.amd.push({name: "amd_#{test.name}", files: files, build: {files: test_patterns, destination: "_temp/amd/#{test.name}", options: _.extend({path_files: path_files}, AMD_OPTIONS)}})

###############################
# Webpack
###############################
TEST_GROUPS.webpack = []
for file in FILES.tests_webpack
  try webpack_config = require "../#{file}"
  if webpack_config
    test_file = webpack_config.output.filename
    TEST_GROUPS.webpack.push({name: "webpack_#{path.basename(test_file, '.js')}", files: [test_file]})

###############################
# Browserify
###############################
TEST_GROUPS.browserify = []
for test_name, test_info of require('./browserify/tests')
  TEST_GROUPS.browserify.push({name: "browserify_#{test_name}", files: [test_info.output], build: {destination: test_info.output, options: test_info.options, files: test_info.files}})
