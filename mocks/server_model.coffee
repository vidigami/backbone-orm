util = require 'util'
_ = require 'underscore'
Backbone = require 'backbone'

module.exports = class MockServerModel extends Backbone.Model
  sync: require('../memory_backbone_sync')(MockServerModel)
