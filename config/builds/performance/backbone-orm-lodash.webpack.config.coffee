_ = require 'underscore'

module.exports = _.extend {}, (require '../../webpack/base-config.coffee'), {
  entry: './backbone-orm.js'
  output:
    library: 'BackboneORM'
    libraryTarget: 'umd'

  externals: [
    {stream: 'stream'}
  ]
}

module.exports.resolve.alias =
  underscore: require.resolve('lodash')
