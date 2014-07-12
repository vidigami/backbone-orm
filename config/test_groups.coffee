fs = require 'fs'
path = require 'path'
_ = require 'underscore'
gutil = require 'gulp-util'
FILES = require './files'

module.exports = TEST_GROUPS = {}
TEST_GROUPS.browser_globals = [{name: "browser_globals", files: FILES.local_dependancies.concat(['./backbone-orm.js', './test/parameters.coffee', './test/option_sets.coffee'], FILES.tests_core)}]

# ###############################
# # AMD
# ###############################
# AMD_OPTIONS = require './amd/gulp-options'
# TEST_GROUPS.amd = []
# for test in TEST_GROUPS.full.concat(TEST_GROUPS.core) when (test.name.indexOf('_min') < 0 and test.name.indexOf('legacy_') < 0 and test.name.indexOf('parse_') < 0)
#   test_files = ['./node_modules/chai/chai.js'].concat(test.files)
#   files = []
#   files.push({pattern: file}) for file in ['./vendor/optional/requirejs-2.1.14.js']
#   files.push({pattern: file, included: false}) for file in test_files.slice(0, -1)
#   files.push({pattern: './_temp/amd/test/parameters.js'})
#   files.push({pattern: file}) for file in ["./_temp/amd/#{test.name}/#{gutil.replaceExtension(path.basename(test_files.slice(-1)[0]), '.js')}"]
#   TEST_GROUPS.amd.push({name: "amd_#{test.name}", files: files, build: {files: test_files, destination: "_temp/amd/#{test.name}", options: _.extend({files: test_files.slice(0, -1)}, AMD_OPTIONS)}})

###############################
# Webpack
###############################
TEST_GROUPS.webpack = []
# TEST_GROUPS.webpack.push({name: "webpack_generated", files: ['./_temp/webpack/backbone-orm.tests.js']})
# TEST_GROUPS.webpack.push({name: "webpack_full", files: ['./_temp/webpack/backbone-orm.tests_new.js']})
for file in FILES.tests_webpack
  try webpack_config = require "../#{file}"
  if webpack_config
    test_file = webpack_config.output.filename
    TEST_GROUPS.webpack.push({name: "webpack_#{path.basename(test_file, '.js')}", files: [test_file]})

# ###############################
# # Browserify
# ###############################
# TEST_GROUPS.browserify = []
# for test_name, test_info of require('./browserify/tests')
#   TEST_GROUPS.browserify.push({
#     name: "browserify_#{test_name}",
#     files: test_info.output,
#     build: {destination: test_info.output, options: test_info.options, files: test_info.files}
#   })
