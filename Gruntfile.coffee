LIBRARY_WRAPPERS = require './client/config_library_wrap'

module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    shell:
      library:
        options: {stdout: true, stderr: true}
        command: 'brunch build -c client/brunch_config.coffee'
      vendor:
        options: {stdout: true, stderr: true}
        command: 'browserify -r underscore -r backbone -r moment -r inflection > test/web/vendor-browserify.js'

    wrap:
      library:
        cwd: '_build/'
        expand: true
        src: ['backbone-orm.js'],
        dest: '_build/',
        options: {wrapper: [LIBRARY_WRAPPERS.start, LIBRARY_WRAPPERS.end]}

      license:
        cwd: '_build/'
        expand: true
        src: ['backbone-orm*.js'],
        dest: './',
        options: {wrapper: [LIBRARY_WRAPPERS.license, '']}

    uglify:
      library: {expand: true, cwd: '_build/', src: ['*.js'], dest: '_build/', ext: '-min.js'}
      vendor: {expand: true, cwd: 'client/', src: ['backbone-orm-vendor.js'], dest: 'client/', ext: '-min.js'}

    clean:
      build: ['_build']

  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-wrap'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-uglify'

  grunt.registerTask 'default', ['shell:library', 'wrap:library', 'uglify:library', 'wrap:license', 'clean:build']
  grunt.registerTask 'vendor', ['shell:vendor']
