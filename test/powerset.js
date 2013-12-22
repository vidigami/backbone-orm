/* vim:set ts=2 sw=2 sts=2 expandtab */
/*jshint asi: true undef: true es5: true node: true browser: true devel: true
         forin: true latedef: false globalstrict: true*/

"use strict";

//({urequire: rootExports: 'powerset'});

var reducer = Array.prototype.reduce
module.exports = function powerset(input) {
  /**
  Creates a [power set](http://en.wikipedia.org/wiki/Power_set) of an array
  like `input`.

  ## Examples

  powerset([0, 1, 2])   // [[], [0], [1], [0,1], [2], [0,2], [1,2], [0,1,2]]
  powerset("ab")        // [[], ["a"], ["b"], ["a","b"]]
  **/
  return reducer.call(input, function(powerset, item, index) {
    var next = [ item ]
    return powerset.reduce(function(powerset, item) {
      powerset.push(item.concat(next))
      return powerset
    }, powerset)
  }, [[]])
}
