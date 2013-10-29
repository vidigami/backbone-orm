startsWith = (string, substring) -> string.lastIndexOf(substring, 0) is 0

exports.config =
  sourceMaps: false
  paths:
    public: './_build'
    watched: ['src', 'client/node-no-stream']
  modules:
    definition: false
    nameCleaner: (path) ->
      path = path.replace(/^src\//, 'backbone-orm/lib/')
      path = path.replace(/^client\/node-no-stream\//, '')
  conventions:
    ignored: (path) -> return startsWith(path, 'src/node')
  files:
    javascripts:
      joinTo:
        'backbone-orm.js': /^src|^client\/node-no-stream/
      order:
        before: []
