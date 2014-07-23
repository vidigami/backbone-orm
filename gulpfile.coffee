path = require 'path'
Async = require 'async'
es = require 'event-stream'

gulp = require 'gulp'
gutil = require 'gulp-util'
webpack = require 'gulp-webpack-config'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
header = require 'gulp-header'
zip = require 'gulp-zip'
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
  # return stream instead of explicit callback https://github.com/gulpjs/gulp/blob/master/docs/API.md

gulp.task 'watch', ['build'], (callback) ->
  return gulp.watch './src/**/*.coffee', -> buildLibraries()

gulp.task 'minify', ['build'], (callback) ->
  return gulp.src(['*.js', '!*.min.js', '!_temp/**/*.js', '!node_modules/'])
    .pipe(uglify())
    .pipe(rename({suffix: '.min'}))
    .pipe(header(HEADER, {pkg: require './package.json'}))
    .pipe(gulp.dest((file) -> file.base))

testNodeFn = (options={}) -> (callback) ->
  gutil.log 'Running Node.js tests'
  global.test_parameters = require './test/parameters' # ensure that globals for the target backend are loaded
  gulp.src('test/spec/**/*.tests.coffee')
    .pipe(mocha(options))
    .pipe es.writeArray (err, array) ->
      delete global.test_parameters # cleanup globals
      callback(err)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

testBrowsersFn = (options={}) -> (callback) ->
  gutil.log 'Running Browser tests'
  (require './config/karma/run')(options, callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test-node', ['minify'], testNode = testNodeFn()
gulp.task 'test-browsers', ['minify'], testBrowsers = testBrowsersFn()
gulp.task 'test', ['minify'], (callback) ->
  Async.series [testNode, testBrowsers], (err) -> if err then process.exit(1) else callback(err)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test-node-quick', ['build'], testNodeQuick = testNodeFn({grep: '@no_options'})
gulp.task 'test-browsers-quick', ['build'], testBrowsersQuick = testBrowsersFn({client: {args: ['--grep', '@no_options']}})
gulp.task 'test-quick', ['build'], (callback) ->
  Async.series [testNodeQuick, testBrowsersQuick], (err) -> if err then process.exit(1) else callback(err)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'benchmark', ['build'], (callback) ->
  (require './test/lib/run_benchmarks')(callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'zip', ['minify'], (callback) ->
  return gulp.src(['*.js'])
    .pipe(es.map (file, callback) -> file.path = file.path.replace('stream', 'optional/stream'); callback(null, file))
    .pipe(zip('backbone-orm.zip'))
    .pipe(gulp.dest('./'))

gulp.task 'release', ['build', 'zip'], ->
