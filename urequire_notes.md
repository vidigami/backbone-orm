# Notes - using uRequire 0.6.9

Defined simple grunt tasks, `webCombined, `webMin` and `WebUMD` that all derive from `_defaults`.

Features handled entirely by uRequire:

 * inject VERSION on `index.js` dynamically

 * banner is added to `-combined.js` or `index.js` on UMD

 * 'BackboneORM' is exported to root (window) declaratively - any module could be exported like this

 * 'underscore' is exported as '_' to all modules - as a bundle global, as an example. It could be removed from the code and it will eventually save some bytes.

 * uglification (webMin)

 * `watch` tasks, for rapid rebuilds of only changes files.

The rest of the gruntfile has some enhancements.

 * runs phantomjs for the web tests - 'mocha' task

 * some registerTask etc best practices :-)

Also `uglify` and `wrap` are not needed at all for uRequire based builds.

# Issues

## Circular dependencies (solved)

`utils` requires `extensions/model` and vise versa

    # utils.coffee line 120:
    modelExtensions = require('./extensions/model') unless modelExtensions # break dependency cycle

This is a known [AMD problem](http://stackoverflow.com/questions/4881059/how-to-handle-circular-dependencies-with-requirejs-amd) and urequire solves this by having [`exports` always available](http://urequire.org/masterdefaultsconfig.coffee#build.injectexportsmodule).

The change the code is to *degrade* `Utils` from being a class and just `_.extend exports, Utils` object as the module's value.

## Tests on Web

Right now all unit tests run from hardcoded paths, requiring each module as needed. I managed to run some tests on browser & phantomjs as UMD modules, against the UMD build of the library.

Issues:

* To properly test **the packaged library (eg -combined.min.js) though**, the regression / non-unit specs that can, should use the library only from exported modules only, the same way a user would use it (i.e `window.Backbone-ORM`).

* `unit/all_generators` doesnt work, they use things in `/node` - see `suiteWeb.coffee` - they should attempt to work on browser ?

* `./unit/cursor`  runs no tests on web.

## Shims

They are added to src/ and test/ by hand - they are then ommited from the builds they dont belong, and it good they are .js to easily ignore them. I will handle it in a next urequire version to remain in a different dir.

# Suggestions

## npm

I suggest to use grunt for all npm "scripts:", to have a unified & *richer* approach, eg

    "scripts": {
      "test": "grunt build test"
      "build": "grunt build"
    }

which just needs a `before_script: - "npm install -g grunt-cli"` in `.travis.yml`.

I only changed build & watch, as an example & to cater for VERSION injection

## bower

All web-looking stuff & tests should use `bower_components` instead of `node_modules`.

Caveats:

* `$ grunt library` that runs `$ brunch build -c client/brunch_config.coffee` reports 3rd party libraries errors, needs --force

    error: { [Error: Component must have "/mnt/tc/DevelopmentProjects/WebStormWorkspace/p/backbone-orm/bower_components/underscore/bower.json"] code: 'NO_BOWER_JSON' }

## Minors

Cant pass `NODE_ENV = 'test'` to 'shell' :-(