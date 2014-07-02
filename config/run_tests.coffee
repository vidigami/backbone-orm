Queue = require 'queue-async'
Wrench = require 'wrench'
es = require 'event-stream'

gulp = require 'gulp'
gutil = require 'gulp-util'
karma = require './karma/run'
mocha = require 'gulp-mocha'

module.exports = (callback) ->
  queue = new Queue(1)

  # install backbone-orm
  queue.defer (callback) ->
    gulp.src(['./backbone-orm.js', './package.json'])
      .pipe(gulp.dest('node_modules/backbone-orm'))
      .on('end', callback)

  # run node tests
  queue.defer (callback) ->
    gutil.log 'Running Node.js tests'
    gulp.src('test/suite.coffee')
      .pipe(mocha({}))
      .pipe(es.writeArray (err, array) -> callback(err))

  # run browser tests
  queue.defer (callback) ->
    Wrench.rmdirSyncRecursive('node_modules/backbone-orm', true)
    gutil.log 'Running Browser tests'
    karma(callback)

  queue.await (err) ->
    Wrench.rmdirSyncRecursive('node_modules/backbone-orm', true)
    callback(err)
