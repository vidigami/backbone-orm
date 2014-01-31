Please refer to the following release notes when upgrading your version of BackboneORM.

### 0.5.7
* Bug fix: $page with $one wasn't returning an array.
* Disabled ModelIds cache by default and synced to QueryCache enabling

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

