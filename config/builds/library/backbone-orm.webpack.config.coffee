fs = require 'fs'
path = require 'path'
_ = require 'underscore'

module.exports = _.extend {}, (require '../../webpack/base-config.coffee'), {
  entry: './src/index.coffee'
  output:
    library: 'BackboneORM'
    libraryTarget: 'umd2'
    filename: 'backbone-orm.js'

  externals: [
    {jquery: {root: 'jQuery', amd: 'jquery', commonjs: 'jquery', commonjs2: 'jquery'}}
    {underscore: {root: '_', amd: 'underscore', commonjs: 'underscore', commonjs2: 'underscore'}}
    {backbone: {root: 'Backbone', amd: 'backbone', commonjs: 'backbone', commonjs2: 'backbone'}}
    {stream: 'stream'}
  ]
}

module.exports.resolve.alias =
  querystring: path.resolve('./config/node-dependencies/querystring.js')
  url: path.resolve('./config/node-dependencies/url.js')
