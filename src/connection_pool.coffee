MemoryStore = require './cache/memory_store'

module.exports = new MemoryStore({destroy: (url, connection) -> connection.destroy()})
