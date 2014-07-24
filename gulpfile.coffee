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

testNodeFn = (options={}) -> (callback) ->
  gutil.log "Running Node.js tests #{if options.quick then '(quick)' else ''}"
  global.test_parameters = require './test/parameters' # ensure that globals for the target backend are loaded
  mocha_options = if options.quick then {grep: '@no_options'} else {}
  gulp.src('test/spec/**/*.tests.coffee')
    .pipe(mocha(_.extend({reporter: 'dot'}, mocha_options)))
    .pipe es.writeArray (err, array) ->
      delete global.test_parameters # cleanup globals
      callback(err)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

testBrowsersFn = (options={}) -> (callback) ->
  gutil.log "Running Browser tests #{if options.quick then '(quick)' else ''}"
  karma_options = if options.quick then {client: {args: ['--grep', '@no_options']}} else {}
  (require './config/karma/run')(karma_options, callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test-node', ['minify'], testNodeFn()
gulp.task 'test-browsers', ['minify'], testBrowsersFn()
gulp.task 'test', ['minify'], (callback) ->
  Async.series [testNodeFn(), testBrowsersFn()], (err) -> if err then process.exit(1) else callback(err)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test-node-quick', ['build'], testNodeFn({quick: true})
gulp.task 'test-browsers-quick', ['build'], testBrowsersFn({quick: true})
gulp.task 'test-quick', ['build'], (callback) ->
  Async.series [testNodeFn({quick: true}), testBrowsersFn({quick: true})], (err) -> if err then process.exit(1) else callback(err)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'benchmark', ['build'], (callback) ->
  (require './test/lib/run_benchmarks')(callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455
