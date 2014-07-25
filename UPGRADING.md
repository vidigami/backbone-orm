### From 0.5.x to 0.6.1

1. All references to BackboneORM.CacheSingletons.ModelCache.configure should be replaces with configure.

```
# change
BackboneORM.CacheSingletons.ModelCache.configure(options)

# to
BackboneORM.configure({model_cache: options})
```

2. All references to paths within the lib directory should be replaced with objects BackboneORM.

```
# change
JSONUtils = require 'backbone-orm/json_utils'

# to (JavaScript)
var JSONUtils = require('backbone-orm').JSONUtils;

# or (CoffeeScript)
{JSONUtils} = require 'backbone-orm'
```

3. JSONUtils.parse no longer coerces all values to integers. Pass a specific model to infer correctly the field type.

```
# change
var parsed_query = JSONUtils.parse(req.query);

# to
var parsed_query = JSONUtils.parse(req.query, model_type);
```