WRAPPERS = require './client/config_wrap_js'

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
        options: {wrapper: [WRAPPERS.library_start, WRAPPERS.library_end]}

      license:
        cwd: '_build/'
        expand: true
        src: ['backbone-orm*.js'],
        dest: 'client/',
        options: {wrapper: [WRAPPERS.library_license, '']}

      vendor:
        cwd: 'client/'
        expand: true
        src: ['bborm-vendor.js'],
        dest: 'client/',
        options: {wrapper: [WRAPPERS.vendor_start, WRAPPERS.vendor_end]}

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
