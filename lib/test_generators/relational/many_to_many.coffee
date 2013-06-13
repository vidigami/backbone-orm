# TODO: explain required set up

# each model should be fabricated with 'id', 'name', 'created_at', 'updated_at'
# beforeEach should return the models_json for the current run
module.exports = (options) ->
  MODEL_TYPE = options.model_type
  BEFORE_EACH = options.beforeEach
  MODELS_JSON = null

  util = require 'util'
  assert = require 'assert'
  _ = require 'underscore'
  Queue = require 'queue-async'

  Utils = require '../../../utils'
  adapters = Utils.adapters

  describe 'Model.relation', ->

    beforeEach (done) ->
      BEFORE_EACH (err, models_json) ->
        return done(err) if err
        return done(new Error "Missing models json for initialization") unless models_json
        MODELS_JSON = models_json
        done()
