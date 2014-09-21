_ = require 'underscore'

module.exports = _.extend {}, (require '../../webpack/base-config.coffee'), {
  entry: './backbone-orm.js'
  output:
    library: 'BackboneORM'
    libraryTarget: 'umd2'
    filename: 'backbone-orm-lodash.js'

  externals: [
    {stream: 'stream'}
  ]
}

module.exports.resolve.alias =
  underscore: require.resolve('lodash')
