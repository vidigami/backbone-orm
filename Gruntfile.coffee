LIBRARY_WRAPPERS = require './client/config_library_wrap'
VENDOR_WRAPPERS = require './client/config_vendor_wrap'

module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    shell:
      library:
        options: {stdout: true}
        command: 'brunch build -c client/config.coffee'
      vendor:
        options: {stdout: true}
        command: 'browserify -r underscore -r backbone -r moment -r inflection > client/bborm-vendor.js'

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
        dest: 'client/',
        options: {wrapper: [LIBRARY_WRAPPERS.license, '']}

      vendor:
        cwd: 'client/'
        expand: true
        src: ['bborm-vendor.js'],
        dest: 'client/',
        options: {wrapper: [VENDOR_WRAPPERS.start, VENDOR_WRAPPERS.end]}

    replace:
      vendor:
        src: ['client/bborm-vendor.js']
        dest: 'client/'
        replacements: [{
          from: 'require=(function'
          to: 'var require=(function'
        }]

    uglify:
      library: {expand: true, cwd: '_build/', src: ['*.js'], dest: '_build/', ext: '-min.js'}
      vendor: {expand: true, cwd: 'client/', src: ['bborm-vendor.js'], dest: 'client/', ext: '-min.js'}

    clean:
      build: ['_build']

  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-wrap'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-text-replace'

  grunt.registerTask 'default', ['shell:library', 'wrap:library', 'uglify:library', 'wrap:license', 'clean:build']
  grunt.registerTask 'vendor', ['shell:vendor', 'replace:vendor', 'wrap:vendor', 'uglify:vendor', 'clean:build']
