Please refer to the following release notes when upgrading your version of BackboneORM.

### 0.7.13
* Monkey patch for Backbone 1.2.x regression bug in _removeModels

### 0.7.12
* Monkey patch for Backbone 1.2.1 regression bug in _removeModels

### 0.7.11
* Added tests for nested json find on dynamic models

### 0.7.10
* Bug fix and optimizations for large data sets to use process.nextTick (node) or setImmediate (browser)
* Bug fix for cache replacing desired model during collection array set
* Various optimizations

### 0.7.9
* Bug fix clone to not cache non loaded models

### 0.7.8
* Bug fix DatabaseURL for BackboneHTTP join tables

### 0.7.7
* Bug fix for dirty checking in 0.7.4

### 0.7.6
* Bug fix for trying to remove an embedded model

### 0.7.5
* Bug fix for initializing collection during clone

### 0.7.4
* Bug fix for dirty check when modifying a relationship

### 0.7.3
* Bug fix for $unique with $page

### 0.7.2
* Added $exists query

### 0.7.1
* Bug fix for JSONUtils.parse for array type
* Fixed references to 0.7.x

### 0.7.0
* Implemented strict-json syntax in the query string, eg. https://things/1?string="value"&number=1. Use JSONUtils.parseQuery instead of JSONUtils.parse.
* Removed parseParams. Use JSONUtils.parseField(value, model_type, 'id') instead
* Bug fix to respect whitelisting in modelJSONSave
* Naming consistency for whitelist (removed hypenated version like white_list).
* Renamed JSONUtils.toQuery to JSONUtils.querify.

### 0.6.6
* Fixed error messages not being passed through when using a cache sync

### 0.6.5
* Bug fix for relationships not being destroyed

### 0.6.4
* Bug fix for relationships not being destroyed
* Memory sync optimizations

### 0.6.3
* Added manual field option for ids so they can be manually set rather than auto-incremented
* Added tests for dynamic attributes
* Added tests for id types and fixed broken lookups

### 0.6.2
* Added unique to select distinct records

### 0.6.1
* removed lib folder from release
* simplified build and test

### 0.6.0
* See [upgrade notes](https://github.com/vidigami/backbone-orm/blob/master/UPGRADING.md) for upgrading pointers from 0.5.x
* BREAKING: Removed QueryCache
* BREAKING: Moved model cache to set configured using BackboneORM.configure({model_cache: options})
* BREAKING: Deprecated Utils.inspect and moved to JSONUtils.stringify
* BREAKING: Removed ModelCache.hardReset or ModelCache.reset instead
* BREAKING (server): Moved to webpack for industrial packaging across Node.js and browser. You must use the browser api; for example, replace require('backbone-orm/json_utils') with require('backbone-orm').JSONUtils
* BREAKING: the model cache will generate unique id (cuid) for each model to identify it in the cache
* Redesigned tests so they can be run from the command line and handle TDD correctly
* Made patchAdd fail if the record already exists
* Removed dependency on moment
* Preserved integers when serialized in JSON: https://github.com/vidigami/backbone-orm/issues/26
* Added type() and idType() to Schema API to check types of attributes
* Added configurable naming_conventions: 'underscore', 'camelize', 'classify'. Configure using BackboneORM.configure({naming_conventions: 'camelize'})
* Added base conventions for easing overrides: BackboneORM.BaseConvention. To roll your own: monkey patch it, derive from it, refer to it from your own conventions, etc.

### 0.5.18
* Fixed exists bug

### 0.5.17
* Fixed module system problems

### 0.5.16
* Added schema helpers: columns, joinTables, relatedModels

### 0.5.15
* Fix tests

### 0.5.14
* Bug fix for join table query: merge query instead of overwrite
* Fix for CoffeeScript change

### 0.5.13
* Fix for Component: https://github.com/vidigami/backbone-orm/issues/18

### 0.5.12
* Added unset functionality for multiple unset: https://github.com/vidigami/backbone-mongo/issues/7

### 0.5.11
* publish on component. Removed client dependency on inflection by burning into library.

### 0.5.10
* npm re-publish

### 0.5.9
* Compatability fix for Backbone 1.1.1

### 0.5.8
* Lock Backbone.js to 1.1.0 until new release compatibility issues fixed

### 0.5.7
* Bug fix: $page with $one wasn't returning an array.
* Disabled ModelIds cache by default and synced to QueryCache enabling
* Added schema to collection so it can be passed to a model

### 0.5.6
* Removed default each limit. Must now be explicitly passed.
* Bug fix: $select with toModels.

### 0.5.5
* Added $nin support
* Allow for manual model_type_id

### 0.5.4
* Bug fix: references to util Node.js module

### 0.5.3
* Bug fix: set ids for relationship incorrectly reported the relationship as loaded
* Bug fix: was not handling idAttribute
* added fetchRelated helper
* set null defaults for uninitialized One relationships for consistency with Knockback

### 0.5.2
* AMD module improvements: made anonymous definition and added require
* Global symbol: gave own name BackboneORM instead of Backbone.ORM

### 0.5.1
* Node < 0.10 stream check

### 0.5.0
* Initial release

