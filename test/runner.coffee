Mocha = require 'mocha'
path = require 'path'
fs = require 'fs'

mocha = new Mocha(
  reporter: 'spec'
  ui: 'bdd'
  timeout: 10000
#  bail: true
)

#mocha.addFile('./test/suite.js')
mocha.addFile('./test/suite.coffee')

runner = mocha.run -> console.log('finished'); process.exit(0)

runner.on 'pass', (test) -> console.log '... %s passed', test.title
runner.on 'fail', (test) -> console.log '... %s failed', test.title
