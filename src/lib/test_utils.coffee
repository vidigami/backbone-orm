module.exports = class TestUtils
  @optionSets: ->
    option_sets = [
      {'cache': false, 'embed': false, '$tags': '@no_cache @no_embed @no_options'},
      {'cache': true, 'embed': false, '$tags': '@cache @no_embed'},
      {'cache': false, 'embed': true, '$tags': '@no_cache @embed'},
      {'cache': true, 'embed': true, '$tags': '@cache @embed'}
    ]
