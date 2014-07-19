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
  Dependencies: Backbone.js, Underscore.js, and Moment.js.
*/\n
"""

gulp.task 'build', buildLibraries = (callback) ->
  gulp.src('config/builds/library/**/*.webpack.config.coffee', {read: false, buffer: false})
    .pipe(webpack())
    .pipe(header(HEADER, {pkg: require('./package.json')}))
    .pipe(gulp.dest((file) -> file.base))
    .on('end', callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'watch', ['build'], (callback) ->
  gulp.watch './src/**/*.coffee', -> buildLibraries(->)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'minify', ['build'], (callback) ->
  gulp.src(['*.js', '!*.min.js', '!_temp/**/*.js', '!node_modules/'])
    .pipe(uglify())
    .pipe(rename({suffix: '.min'}))
    .pipe(header(HEADER, {pkg: require('./package.json')}))
    .pipe(gulp.dest((file) -> file.base))
    .on('end', callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test-node', ['minify'], testNode = (options, callback) ->
  [options, callback] = [{}, options] if arguments.length is 1

  gutil.log 'Running Node.js tests'
  global.test_parameters = require './test/parameters' # ensure that globals for the target backend are loaded
  gulp.src('test/spec/**/*.tests.coffee')
    .pipe(mocha({}))
    .pipe es.writeArray (err, array) ->
      delete global.test_parameters # cleanup globals
      callback(err)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test-browsers', ['minify'], testBrowsers = (options, callback) ->
  [options, callback] = [{}, options] if arguments.length is 1

  gutil.log 'Running Browser tests'
  (require './config/karma/run')(options, callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test', ['minify'], (callback) ->
  Async.series [testNode, testBrowsers], (err) -> process.exit(if err then 1 else 0)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test-quick', ['build'], (callback) -> testNode({quick: true}, callback); return # promises workaround: https://github.com/gulpjs/gulp/issues/455
gulp.task 'test-node-quick', ['build'], (callback) -> testNode({quick: true}, callback); return # promises workaround: https://github.com/gulpjs/gulp/issues/455
gulp.task 'test-browsers-quick', ['build'], (callback) -> testBrowsers({quick: true}, callback); return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'zip', ['minify'], (callback) ->
  gulp.src(['*.js'])
    .pipe(es.map (file, callback) -> file.path = file.path.replace('stream', 'optional/stream'); callback(null, file))
    .pipe(zip('backbone-orm.zip'))
    .pipe(gulp.dest('./'))
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'release', ['build', 'zip'], ->
