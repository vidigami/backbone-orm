Wrench = require 'wrench'
Queue = require 'queue-async'
es = require 'event-stream'

gulp = require 'gulp'
webpack = require 'gulp-webpack-config'
coffee = require 'gulp-coffee'
benchmark = require 'gulp-bench'

module.exports = (callback) ->
  queue = new Queue(1)

  queue.defer (callback) ->
    gulp.src('config/builds/performance/**/*.webpack.config.coffee', {read: false, buffer: false})
      .pipe(webpack())
      .pipe(gulp.dest('./_temp/performance/builds'))
      .on('end', callback)

  queue.defer (callback) ->
    gulp.src('test/performance/**/*.coffee')
      .pipe(coffee())
      .pipe(gulp.dest('./_temp/performance'))
      .on('end', callback)

  queue.defer (callback) ->
    gulp.src('_temp/performance/**/*.benchmark.js')
      .pipe(benchmark())
      .on('end', callback)

  queue.await (err) ->
    Wrench.rmdirSyncRecursive('./_temp', true) unless err
    callback(err)
