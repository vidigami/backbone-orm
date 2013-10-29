startsWith = (string, substring) -> string.lastIndexOf(substring, 0) is 0

exports.config =
  sourceMaps: false
  paths:
    public: './_build'
    watched: ['src', 'client/node-dependencies']
  modules:
    definition: false
    nameCleaner: (path) ->
      path = path.replace(/^src\//, 'backbone-orm/lib/')
      path = path.replace(/^client\/node-dependencies\//, '')
  conventions:
    ignored: (path) -> return startsWith(path, 'src/node')
  files:
    javascripts:
      joinTo:
        'backbone-orm.js': /^src|^client\/node-dependencies/
      order:
        before: []
