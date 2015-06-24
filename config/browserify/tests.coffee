path = require 'path'

module.exports =
  underscore:
    output: './_temp/browserify/backbone-orm-underscore.tests.js'
    files: ['test/parameters.coffee', './test/spec/lib/**/*.tests.coffee', './test/spec/sync/**/*.tests.coffee']
    options:
      basedir: path.resolve(__dirname, '../..')
      ignore: ['../../../option_sets', '../../option_sets', '../../../backbone-orm', '../../../../backbone-orm']
      shim:
        'backbone-orm': {path: './backbone-orm.js', exports: 'BackboneORM', depends: {jquery: 'jQuery', underscore: '_', backbone: 'Backbone', stream: 'stream'}}

  lodash:
    output: './_temp/browserify/backbone-orm-lodash.tests.js'
    files: ['test/parameters.coffee', './test/spec/lib/**/*.tests.coffee', './test/spec/sync/**/*.tests.coffee']
    options:
      basedir: path.resolve(__dirname, '../..')
      ignore: ['../../../option_sets', '../../option_sets', '../../../backbone-orm', '../../../../backbone-orm']
      shim:
        underscore: {path: path.resolve(path.join('.', path.relative('.', require.resolve('lodash')))), exports: '_'}
        'backbone-orm': {path: './backbone-orm.js', exports: 'BackboneORM', depends: {jquery: 'jQuery', underscore: '_', backbone: 'Backbone', stream: 'stream'}}
