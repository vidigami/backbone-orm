module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    copy:
      all:
        expand: true
        src: ['**/*', '!_build', '!_build/**/*', '!**/*.coffee']
        dest: '_build'

    watch:
      coffee:
        files: ['**/*.coffee', '!_build/**/*', '!node_modules/**/*']
        tasks: ['coffee:map']
        options:
          nospawn: true

    coffee:
      map:
        options:
          sourceMap: true
        expand: true
        src: ['**/*.coffee', '!_build/**/*', '!node_modules/**/*']
        dest: '_build'
        ext: '.js'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['copy:all', 'coffee:map', 'watch:coffee']

  # On watch events, inject only the changed files into the config
  grunt.event.on 'watch', (action, filepath) ->
    grunt.config(['coffee', 'map', 'src'], [filepath])

