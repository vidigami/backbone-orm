// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

var shims = require('./_shims');

// NOTE: These type checking functions intentionally don't use `instanceof`
// because it is fragile and can be easily faked with `Object.create()`.
function isArray(ar) {
return shims.isArray(ar);
}
exports.isArray = isArray;

function isBoolean(arg) {
return typeof arg === 'boolean';
}
exports.isBoolean = isBoolean;

function isNull(arg) {
return arg === null;
}
exports.isNull = isNull;

function isNullOrUndefined(arg) {
return arg == null;
}
exports.isNullOrUndefined = isNullOrUndefined;

function isNumber(arg) {
return typeof arg === 'number';
}
exports.isNumber = isNumber;

function isString(arg) {
return typeof arg === 'string';
}
exports.isString = isString;

function isObject(arg) {
return typeof arg === 'object' && arg;
}
exports.isObject = isObject;

function objectToString(o) {
return Object.prototype.toString.call(o);
}
