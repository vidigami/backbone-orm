Please refer to the following release notes when upgrading your version of BackboneORM.

### 0.6.0
* Removed QueryCache
* Moved to webpack for industrial packaging across Node.js and browser
* Redesigned test so they can be run from the command line and handle TDD correctly
* Deprecated Utils.inspect and moved to JSONUtils.stringify
* Removed ModelCache.hardReset or ModelCache.reset instead
* Made patchAdd fail if the record already exists
* Removed dependency on moment
* Provided hooks for changing the conventions for table names, attributes, and foreign keys
* Preserved integers when serialized in JSON: https://github.com/vidigami/backbone-orm/issues/26

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

