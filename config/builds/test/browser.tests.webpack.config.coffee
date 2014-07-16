path = require 'path'
_ = require 'underscore'

module.exports = _.extend  _.clone(require '../../webpack/base-config.coffee'), {
  entry: ['./test/parameters.coffee'].concat((require '../../files').tests_browser)
  output:
    path: '.'
    filename: '_temp/webpack/backbone-orm.tests.js'

  externals: [
    {chai: 'chai'}
  ]
}

module.exports.resolve.alias =
  'backbone-orm': path.resolve('./backbone-orm.js')
  querystring: path.resolve('./config/node-dependencies/querystring.js')
  url: path.resolve('./config/node-dependencies/url.js')
  stream: path.resolve('./stream.js')
