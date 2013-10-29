module.exports = class ModelStream extends require('stream').Readable
  constructor: (@model_type, @query={}) -> super {objectMode: true}; @ended  = false
  _read: ->
    return if @ended
    done = (err) => @ended = true; @emit('error', err) if err; @push(null)
    @model_type.batch @query, {}, done, (model, callback) => @push(model); callback()
