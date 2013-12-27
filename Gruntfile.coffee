# requires: { grunt:"0.4.x", urequire: "0.6.9" }
_ = require 'underscore'
startsWith = (string, substring) -> string.lastIndexOf(substring, 0) is 0
endsWith = (string, substring) -> string.slice(string.length - substring.length) is substring
LIBRARY_WRAPPERS = require './client/config_library_wrap'

S = if process.platform is 'win32' then '\\' else '/' # OS directory separator
nodeBin = "node_modules#{S}.bin#{S}"

module.exports = (grunt) ->
  pkg = grunt.file.readJSON('package.json') # deassociate from gruntConfig

  gruntConfig =

    shell:
      library: command: "#{nodeBin}brunch build -c client/brunch_config.coffee"
      vendor: command: "#{nodeBin}browserify -r underscore -r backbone -r moment -r inflection > test/web/vendor-browserify.js"
      mochaCmd:
        command: "#{nodeBin}mocha test/suite.coffee --compilers coffee:coffee-script --timeout 10000" # --reporter spec
        #options: execOptions: env: do -> process.env.NODE_ENV = 'test'; process.env   # not working with --reporter spec, `stdout maxBuffer exceeded`
      options: {verbose: true, failOnError: true, stdout: true, stderr: true}

    wrap:
      library:
        cwd: "_build/"
        expand: true
        src: ['backbone-orm.js']
        dest: "_build/"
        options: {wrapper: [LIBRARY_WRAPPERS.start, LIBRARY_WRAPPERS.end]}

      license:
        cwd: "_build/"
        expand: true
        src: ['backbone-orm*.js'],
        dest: './',
        options: {wrapper: [LIBRARY_WRAPPERS.license, '']}

    uglify:
      library: {expand: true, cwd: "_build/", src: ['*.js'], dest: "_build/", ext: '.min.js'}
      vendor: {expand: true, cwd: 'client/', src: ['backbone-orm-vendor.js'], dest: 'client/', ext: '.min.js'}

    zip:
      library:
        dest: 'client/backbone-orm.zip'
        router: (filepath) ->
          return "optional/#{filepath}" if startsWith(filepath, 'stream')
          filepath
        src: ['backbone-orm*.js', 'stream*.js']

    clean: build: ['lib']

    watch:
      webUMD: files: ["src/**/*"], tasks: ['urequire:webUMD']
      webCombined: files: ["src/**/*"], tasks: ['urequire:webCombined']
      compile: files: ["src/**/*"], tasks: ['urequire:compile']
      specs: files: ["test/**/*"], tasks: ['urequire:tests']
      options: spawn: false

    mocha: # runs mocha on phantomjs
      plainScript: # NOT WORKING YET
        src: [
          #"_build/test/web/SpecRunner_almondJs_noAMD_plainScript.html"
          #"_build/test/web/SpecRunner_almondJs_noAMD_plainScript_min.html"
        ]
        options: run: true
      AMD:
        src: [
          "_build_urequire/test/web/SpecRunner_unoptimized_AMD.html"
          #"_build/test/web/SpecRunner_almondJs_AMD.html"
        ]

    urequire:
      _defaults: # for all builds, web-only & node
        path: 'src'
        main: 'index'
        dependencies:
          exports: root: index: 'BackboneORM'
          node: [ 'node/**', '!', (d)-> d in [ 'stream', 'util', 'url', 'querystring' ] ] # 'stream' optionaly available as local

        resources: [
          [ '+injectVERSION', ['index.js'], (m)-> m.beforeBody = "var VERSION = '#{pkg.version}';\n" ]
        ]

        template:
          name: 'UMDplain'
          banner: LIBRARY_WRAPPERS.license
        clean: true
        #verbose: true
        #debugLevel: 0

      webUMD: # uses the utils.js, url.js etc that shadow node's modules, so itc can be used on the web (and node).
        dstPath: "_build_urequire/UMD" # 'lib' so it works with specsWeb, until partial dep path can be replaced by urequire :-)

      webCombined:
        dstPath: "_build_urequire/backbone-orm-combined"
        template: 'combined'

      # some example optimizations, used optionally only by webMin
      _optionalDefaults:
        derive: ['_defaults']

        dependencies: exports: bundle:
          'underscore': '_'       # used in most files - inject in all
          'backbone': 'Backbone'  # & save space on combined (& typing in each file ;-)

        resources: [
          [ '+removeSomeCode', 'remove any debuging/non needed code from all or specific files', ['index.js'], #for example
            (m)-> m.replaceCode 'if ((typeof window !== "undefined" && window !== null) && require.shim) {}' ]

          # trick to merge common coffeescript-generated code like `__extends` http://urequire.org/resourceconverters.coffee#add-some-coffeescript-define-and-merge
          # saves 3 kbytes in non-mininified (if you 'd cater for whitespace)
          (findRC)->(findRC 'wrapCoffeeDefineCommonJS').enabled = true; null
        ]

      webMin:
        derive: ['_optionalDefaults']
        dstPath: "_build_urequire/backbone-orm-combined.min.js"
        template: 'combined'
        optimize: true # uglify2 defaults

      # a quick compile i.e `coffee -o lib -c src` + VERSION injection on index.js
      # without module translation, just coffee with uRequire
      compile:
        filez: ['**/*.coffee']  # accept only `.coffee`, i.e exclude .js shims
        dstPath: 'lib'
        resources: [
          [ '#justCoffeeCompile' ]  # marks all files as TextResource, (not modules, since we dont want to convert)
          [ '#injectVERSIONAsText', ['index.js'], (r)-> "var VERSION = '#{pkg.version}';\n" + r.converted ]
          [ '#simulate Generated by CoffeeScript comment for git`s sake', /./,
            (r)-> "// Generated by CoffeeScript 1.6.3\n" + r.converted ]

          (findRC)->(findRC 'wrapCoffeeDefineCommonJS').enabled = false; null # make sure `define ->` trick is off
        ]

      # test related
      libUMD: # take the place of /lib, for testing the UMDs on nodejs
        dstPath: "lib"

      libUMDnode: # UMD but use node's modules, by excluding shims that **shadow node's modules**
        filez: [/./, '!', (f)-> endsWith f, '.js' ]
        dstPath: "lib"

      specsWeb:
        derive: []
        path: 'test'
        filez: [/./, '!web/browserify-bundle.js']
        copy: /./
        template: 'UMDplain'
        dstPath: '_build_urequire/test'
        dependencies:
          node: [ '!', (d)-> d in [ 'stream', 'assert', 'util', 'querystring' ] ] # 'stream' optionaly available as local
          replace: '../UMD': '../lib|' # >= 0.6.10beta1

  ### shortcuts generation ###
  splitTasks = (tasks)-> if !_.isString tasks then tasks else (_.filter tasks.split(/\s/), (v)-> v)
  for task in ['shell', 'urequire'] # shortcut to all "shell:cmd, urequire:UMD" etc
    grunt.registerTask cmd, splitTasks "#{task}:#{cmd}" for cmd of gruntConfig[task]

  grunt.registerTask shortCut, splitTasks tasks for shortCut, tasks of { # usefull when many tasks :-)
    default:    ['shell:library', 'wrap:library', 'uglify:library', 'wrap:license', 'zip:library', 'clean:build']
    vendor:     ['shell:vendor']

    build:      "urequire:compile"             #  allows inject of VERSION
    webAll:     "webUMD webCombined webMin"    # `urequire:xxx` shortcuted above

    # specs
    libSpecs:        "build mochaCmd"
    libUMDSpecs:     "libUMD mochaCmd"
    libUMDnodeSpecs: "libUMDnode mochaCmd"
    webSpecs:        "webUMD specsWeb mocha"

    allSpecs:        "libUMDSpecs libUMDnodeSpecs webSpecs libSpecs"
  }

  grunt.loadNpmTasks task for task in [
    'grunt-contrib-clean'
    'grunt-shell'
    'grunt-zip'
    'grunt-wrap'
    'grunt-contrib-uglify'
    'grunt-urequire'
    'grunt-contrib-watch' # watch while we build
    'grunt-mocha'         # mocha & phantomj
  ]

  grunt.initConfig gruntConfig