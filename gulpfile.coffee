path = require 'path'
_ = require 'underscore'
Async = require 'async'
es = require 'event-stream'

gulp = require 'gulp'
gutil = require 'gulp-util'
webpack = require 'gulp-webpack-config'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
header = require 'gulp-header'
mocha = require 'gulp-mocha'

HEADER = """
/*
  <%= file.path.split('/').splice(-1)[0].replace('.min', '') %> <%= pkg.version %>
  Copyright (c) 2013-#{(new Date()).getFullYear()} Vidigami
  License: MIT (http://www.opensource.org/licenses/mit-license.php)
  Source: https://github.com/vidigami/backbone-orm
  Dependencies: Backbone.js and Underscore.js.
*/\n
"""

gulp.task 'build', buildLibraries = ->
  return gulp.src('config/builds/library/**/*.webpack.config.coffee', {read: false, buffer: false})
    .pipe(webpack())
    .pipe(header(HEADER, {pkg: require './package.json'}))
    .pipe(gulp.dest('.'))

gulp.task 'watch', ['build'], (callback) ->
  return gulp.watch './src/**/*.coffee', -> buildLibraries()
  return gulp.watch './src/**/*.coffee', -> buildLibraries()

gulp.task 'minify', ['build'], ->
  return gulp.src(['*.js', '!*.min.js', '!_temp/**/*.js', '!node_modules/'])
    .pipe(uglify())
    .pipe(rename({suffix: '.min'}))
    .pipe(header(HEADER, {pkg: require './package.json'}))
    .pipe(gulp.dest((file) -> file.base))

testNode = (callback) ->
  tags = ("@#{tag.replace(/^[-]+/, '')}" for tag in process.argv.slice(3)).join(' ')
  gutil.log "Running Node.js tests #{tags}"

  global.test_parameters = require './test/parameters' # ensure that globals for the target backend are loaded
  gulp.src('test/spec/**/*.tests.coffee')
    .pipe(mocha({reporter: 'dot', grep: tags}))
    .pipe es.writeArray (err, array) ->
      delete global.test_parameters # cleanup globals
      callback(err)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

testBrowsers = (callback) ->
  tags = ("@#{tag.replace(/^[-]+/, '')}" for tag in process.argv.slice(3)).join(' ')

  gutil.log "Running Browser tests #{tags}"
  (require './config/karma/run')({tags: tags}, callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test-node', ['minify'], testNode
gulp.task 'test-browsers', ['minify'], testBrowsers
gulp.task 'test', ['minify'], (callback) ->
  Async.series [testNode, testBrowsers], (err) -> if err then process.exit(1) else callback(err)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'benchmark', ['build'], (callback) ->
  (require './test/lib/run_benchmarks')(callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455
