module.exports = class TestUtils
  @optionSets: -> [
    {'cache': false, 'embed': false, '$tags': '@no_cache @no_embed @quick'},
    {'cache': true, 'embed': false, '$tags': '@cache @no_embed'},
    {'cache': false, 'embed': true, '$tags': '@no_cache @embed'},
    {'cache': true, 'embed': true, '$tags': '@cache @embed'}
  ]
