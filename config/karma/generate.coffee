fs = require 'fs'
path = require 'path'
_ = require 'underscore'
Queue = require 'queue-async'
es = require 'event-stream'
Wrench = require 'wrench'

gulp = require 'gulp'
gutil = require 'gulp-util'
shell = require 'gulp-shell'
requireSrc = require 'gulp-require-src'
compile = require 'gulp-compile-js'
concat = require 'gulp-concat'
wrapAMD = require 'gulp-wrap-amd-infer'
webpack = require 'gulp-webpack-config'
browserify = require 'gulp-browserify'

FILES = require '../files'
TEST_GROUPS = require '../test_groups'

module.exports = (options={}, callback) ->
  queue = new Queue(1)

  # compile coffeescript config
  queue.defer (callback) ->
    gulp.src(['./test/parameters.coffee'])
      .pipe(compile({coffee: {bare: true}}))
      .pipe(gulp.dest('_temp'))
      .on('end', callback)

  unless options.tags.indexOf('@quick') >= 0

    # install backbone-orm
    queue.defer (callback) ->
      gulp.src(['./backbone-orm.js', './package.json'])
        .pipe(gulp.dest('node_modules/backbone-orm'))
        .on('end', callback)

    # build webpack
    queue.defer (callback) ->
      gulp.src(['config/builds/test/**/*.webpack.config.coffee'], {read: false, buffer: false})
        .pipe(webpack())
        .pipe(gulp.dest('_temp/webpack'))
        .on('end', callback)

    # build test browserify
    for test in TEST_GROUPS.browserify or []
      do (test) -> queue.defer (callback) ->
        gulp.src(test.build.files)
          .pipe(compile({coffee: {bare: true}}))
          .pipe(concat(path.basename(test.build.destination)))
          .pipe(browserify(test.build.options))
          .pipe(gulp.dest(path.dirname(test.build.destination)))
          .on('end', callback)

    # wrap AMD tests
    for test in TEST_GROUPS.amd or []
      do (test) -> queue.defer (callback) ->
        gulp.src(test.build.files)
          .pipe(compile({coffee: {bare: true, header: false}}))
          .pipe(wrapAMD(test.build.options))
          .pipe(gulp.dest(test.build.destination))
          .on('end', callback)

  # uninstall backbone-orm
  queue.await (err) ->
    Wrench.rmdirSyncRecursive('node_modules/backbone-orm', true)
    callback(err)
