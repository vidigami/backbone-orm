Mocha = require 'mocha'
path = require 'path'
fs = require 'fs'

mocha = new Mocha(
  reporter: 'spec'
  ui: 'bdd'
  timeout: 999999
#  bail: true
)

mocha.addFile('./test/suite.coffee')
runner = mocha.run -> console.log('finished')

runner.on 'pass', (test) -> console.log '... %s passed', test.title
runner.on 'fail', (test) -> console.log '... %s failed', test.title
