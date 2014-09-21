path = require 'path'
_ = require 'underscore'

module.exports = _.extend {}, (require '../../webpack/base-config.coffee'), {
  entry: ['./test/parameters.coffee'].concat((require '../../files').tests_browser)
  output:
    filename: 'browser-no-jquery.tests.js'
  externals: [
    {jquery: {root: 'jQuery', amd: 'jquery', commonjs: 'jquery', commonjs2: 'jquery', optional: true}}
    {chai: 'chai'}
  ]
}

module.exports.resolve.alias =
  'backbone-orm': path.resolve('./backbone-orm.js')
  querystring: path.resolve('./config/node-dependencies/querystring.js')
  url: path.resolve('./config/node-dependencies/url.js')
  stream: path.resolve('./stream.js')
