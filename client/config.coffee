startsWith = (string, substring) -> string.lastIndexOf(substring, 0) is 0

exports.config =
  sourceMaps: false
  paths:
    public: './_build'
    watched: ['src', 'node']
  conventions:
    ignored: (path) -> return startsWith(path, 'src/node')
  files:
    javascripts:
      joinTo:
        'backbone-orm.js': /^src|^node/
      order:
        before: []
