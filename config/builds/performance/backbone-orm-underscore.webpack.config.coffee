_ = require 'underscore'

module.exports = _.extend {}, (require '../../webpack/base-config.coffee'), {
  entry: './backbone-orm.js'
  output:
    path: '.'
    filename: '_temp/performance/builds/backbone-orm-underscore.js'
    library: 'BackboneORM'
    libraryTarget: 'umd'

  externals: [
    {stream: 'stream'}
  ]
}

module.exports.resolve.alias =
  underscore: require.resolve('underscore')
