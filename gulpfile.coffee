path = require 'path'
es = require 'event-stream'

gulp = require 'gulp'
gutil = require 'gulp-util'
webpack = require 'gulp-webpack-config'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
header = require 'gulp-header'
zip = require 'gulp-zip'
runTests = null  # require './config/run_tests'  # this require is slow

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
  gulp.watch './src/**/*.coffee', (callback) -> buildLibraries(callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'minify', ['build'], (callback) ->
  gulp.src(['*.js', '!*.min.js', '!_temp/**/*.js', '!node_modules/'])
    .pipe(uglify())
    .pipe(rename({suffix: '.min'}))
    .pipe(header(HEADER, {pkg: require('./package.json')}))
    .pipe(gulp.dest((file) -> file.base))
    .on('end', callback)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'test', ['minify'], (callback) ->
# gulp.task 'test', (callback) ->
  runTests or= require './config/run_tests'
  runTests (err) -> process.exit(if err then 1 else 0)
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'zip', ['minify'], (callback) ->
  gulp.src(['*.js'])
    .pipe(es.map (file, callback) -> file.path = file.path.replace('stream', 'optional/stream'); callback(null, file))
    .pipe(zip('backbone-orm.zip'))
    .pipe(gulp.dest('./'))
  return # promises workaround: https://github.com/gulpjs/gulp/issues/455

gulp.task 'release', ['build', 'zip'], ->
