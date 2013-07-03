module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    copy:
      all:
        expand: true
        src: ['server/**', 'node_modules/**', 'test/**', 'public/**', '!**/*.coffee']
        dest: '_build'
      node_modules:
        expand: true
        src: ['node_modules/**', '!**/*.coffee']
        dest: '_build'
      server:
        expand: true
        src: ['server/**', '!**/*.coffee']
        dest: '_build'
      test:
        expand: true
        src: ['server/**', 'test/**', '!**/*.coffee']
        dest: '_build'
      pub:
        expand: true
        src: ['public/**', '!**/*.coffee']
        dest: '_build'

    watch:
      coffee:
        files: ['server/**/*.coffee', 'node_modules/**/*.coffee', 'test/**/*.coffee', '!node_modules/eco/**/*']
        tasks: ['coffee:map']
        options:
          nospawn: true

    coffee:
      map:
        options:
          sourceMap: true
        expand: true
        src: ['server/**/*.coffee', 'node_modules/**/*.coffee', 'test/**/*.coffee', '!node_modules/eco/**/*']
        dest: '_build'
        ext: '.js'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['copy:all', 'coffee:map', 'watch:coffee']

  # On watch events, inject only the changed files into the config
  grunt.event.on 'watch', (action, filepath) ->
    grunt.config(['coffee', 'map', 'src'], [filepath])

