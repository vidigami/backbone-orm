Mocha = require 'mocha'
path = require 'path'
fs = require 'fs'

mocha = new Mocha({
  reporter: 'dot',
  ui: 'bdd',
  timeout: 999999
})

testDir = './test/'

fs.readdir testDir, (err, files) ->
  console.log(err) if (err)

  files.forEach (file) ->
    if path.extname(file) is '.js' and file isnt 'runner.js'
      console.log('adding test file: %s', file)
      mocha.addFile(testDir + file)

  runner = mocha.run -> console.log('finished')

  runner.on 'pass', (test) -> console.log '... %s passed', test.title

  runner.on 'fail', (test) -> console.log '... %s failed', test.title
