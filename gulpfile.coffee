ee = require 'streamee'
es = require 'event-stream'

gulp = require 'gulp'
gutil = require 'gulp-util'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
license = require 'gulp-license'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
zip = require 'gulp-zip'
browserify = require 'gulp-browserify'

# startsWith = (string, substring) -> string.lastIndexOf(substring, 0) is 0
# LIBRARY_WRAPPERS = require './client/config_library_wrap'

# module.exports = (grunt) ->

#   grunt.initConfig
#     wrap:
#       library:
#         cwd: '_build/'
#         expand: true
#         src: ['backbone-orm.js'],
#         dest: '_build/',
#         options: {wrapper: [LIBRARY_WRAPPERS.start, LIBRARY_WRAPPERS.end]}

#       license:
#         cwd: '_build/'
#         expand: true
#         src: ['backbone-orm*.js'],
#         dest: './',
#         options: {wrapper: [LIBRARY_WRAPPERS.license, '']}

path = require 'path'

class RequireRegister extends require('stream').Transform
  constructor: (@root) -> super {objectMode: true}

  _transform: (file, encoding, callback) ->
    return callback() if file.isNull() or file.stat.isDirectory()
    rel_path = file.path.replace("#{path.resolve(@root) or process.cwd()}/", '')
    file.contents = new Buffer("require.register('#{rel_path.replace(path.extname(rel_path), '')}', function(exports, require, module) {\n#{String(file.contents)}\n});")
    @push(file)
    callback()

gulp.task 'build', ->
  ee.concatenate([
    gulp.src('./src/**/*.coffee').pipe(coffee({bare: true}).on('error', gutil.log)).pipe(new RequireRegister('./src'))
    gulp.src('./client/node-dependencies/**').pipe(new RequireRegister('./client/node-dependencies'))
  ])
    .pipe(concat('backbone-orm.js'))
    .pipe(license('MIT', {organization: 'Vidigami Media Inc (backbone-orm.js 0.5.5)'}))
    .pipe(gulp.dest('./public/'))

gulp.task 'watch', ->
  gulp.run 'build'
  gulp.watch './src/**/*.coffee', -> gulp.run 'build'

gulp.task 'minify', ['build'], ->
  gulp.src('./public/backbone-orm.js')
    .pipe(uglify())
    .pipe(rename({suffix: '.min'}))
    .pipe(gulp.dest('./public/'))

gulp.task 'zip', ['build', 'minify'], ->
  gulp.src(['./public/**/*.js', './stream*.js'])
    .pipe(es.map (file, callback) ->
      file.path = file.path.replace('public/', '')
      file.path = file.path.replace('stream', 'optional/stream')
      callback(null, file))
    .pipe(zip('backbone-orm.zip'))
    .pipe(gulp.dest('./public/'))

gulp.task 'build-browserify-vendor', ->
  gulp.src(['./client/vendor-browserify-config.js'])
    .pipe(browserify())
    .pipe(concat('vendor-browserify.js'))
    .pipe(gulp.dest('./public/'))

gulp.task 'release', ->
  gulp.run 'zip', 'build-browserify-vendor'
