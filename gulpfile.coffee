path = require 'path'
es = require 'event-stream'

gulp = require 'gulp'
gutil = require 'gulp-util'
coffee = require 'gulp-coffee'
compile = require 'gulp-compile-js'
modules = require 'gulp-module-system'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
zip = require 'gulp-zip'

LIBRARY_WRAPPERS = require './client/config_library_wrap'

gulp.task 'build', ->
  gulp.src('src/**/*.coffee').pipe(coffee({bare: true}).on('error', gutil.log))
    .pipe(gulp.dest('lib/'))

gulp.task 'watch', ['build'], ->
  gulp.watch './src/**/*.coffee', -> gulp.run 'build'

gulp.task 'build_client', ->
  gulp.src(['src/**/*.coffee', '!src/node/*.coffee', 'client/node-dependencies/**/*.js'])
    .pipe(es.map (file, callback) -> file.path = file.path.replace("#{path.resolve(dir)}/", '') for dir in ['./src', './client/node-dependencies']; callback(null, file))
    .pipe(compile({coffee: {bare: true}}))
    .pipe(modules({type: 'local-shim', file_name: 'backbone-orm.js', umd: {symbol: 'BackboneORM', dependencies: ['underscore', 'backbone', 'moment', 'inflection']}}))
    .pipe(gulp.dest('./'))

gulp.task 'minify_client', ['build_client'], ->
  gulp.src('backbone-orm.js')
    .pipe(uglify())
    .pipe(rename({suffix: '.min'}))
    .pipe(gulp.dest('./'))

gulp.task 'zip', ['minify_client'], ->
  gulp.src(['*.js'])
    .pipe(es.map (file, callback) -> file.path = file.path.replace('stream', 'optional/stream'); callback(null, file))
    .pipe(zip('backbone-orm.zip'))
    .pipe(gulp.dest('client/'))

gulp.task 'release', ['build', 'zip'], ->
