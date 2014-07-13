module.exports =
  underscore:
    output: './_temp/browserify/backbone-orm-underscore.tests.js'
    files: ['test/parameters.coffee', 'test/option_sets.coffee', './test/spec/lib/**/*.tests.coffee', './test/spec/sync/**/*.tests.coffee']
    options:
      ignore: ['../../../option_sets', '../../../backbone-orm', '../../../../backbone-orm']
      shim:
        'backbone-orm': {path: './backbone-orm.js', exports: 'BackboneORM', depends: {jquery: 'jQuery', underscore: '_', backbone: 'Backbone', moment: 'moment', stream: 'stream'}}

  lodash:
    output: './_temp/browserify/backbone-orm-lodash.tests.js'
    files: ['test/parameters.coffee', 'test/option_sets.coffee', './test/spec/lib/**/*.tests.coffee', './test/spec/sync/**/*.tests.coffee']
    options:
      ignore: ['../../../option_sets', '../../../backbone-orm', '../../../../backbone-orm']
      shim:
        'underscore': {path: './node_modules/lodash/lodash.js', exports: '_'}
        'backbone-orm': {path: './backbone-orm.js', exports: 'BackboneORM', depends: {jquery: 'jQuery', underscore: '_', backbone: 'Backbone', moment: 'moment', stream: 'stream'}}
