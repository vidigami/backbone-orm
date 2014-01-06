path = require 'path'
ee = require 'streamee'
es = require 'event-stream'

gulp = require 'gulp'
gutil = require 'gulp-util'
coffee = require 'gulp-coffee'
define = require 'gulp-wrap-define'
concat = require 'gulp-concat'
license = require 'gulp-license'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
zip = require 'gulp-zip'
browserify = require 'gulp-browserify'

gulp.task 'build', ->
  ee.concatenate([
    gulp.src('./src/**/*.coffee').pipe(coffee({bare: true}).on('error', gutil.log)).pipe(define({root: './src', define: 'require.register'}))
    gulp.src('./client/node-dependencies/**/*.js').pipe(define(root: './client/node-dependencies', define: 'require.register'))
  ])
    .pipe(concat('backbone-orm.js'))
    .pipe(license('MIT', {organization: 'Vidigami Media Inc (backbone-orm.js 0.5.5)'}))
    .pipe(gulp.dest('./dist/'))

gulp.task 'watch', ['build'], ->
  gulp.watch './src/**/*.coffee', -> gulp.run 'build'

gulp.task 'minify', ['build'], ->
  gulp.src('./dist/backbone-orm.js')
    .pipe(uglify())
    .pipe(rename({suffix: '.min'}))
    .pipe(gulp.dest('./dist/'))

gulp.task 'zip', ['build', 'minify'], ->
  gulp.src(['./dist/**/*.js', './stream*.js'])
    .pipe(es.map (file, callback) ->
      file.path = file.path.replace('public/', '')
      file.path = file.path.replace('stream', 'optional/stream')
      callback(null, file))
    .pipe(zip('backbone-orm.zip'))
    .pipe(gulp.dest('./dist/'))

gulp.task 'build-browserify-vendor', ->
  gulp.src(['./client/vendor-browserify-config.js'])
    .pipe(browserify())
    .pipe(concat('vendor-browserify.js'))
    .pipe(gulp.dest('./dist/'))

gulp.task 'release', ->
  gulp.run 'zip', 'build-browserify-vendor'
