### From 0.5.x to 0.6.0

1. All references to BackboneORM.CacheSingletons.ModelCache.configure should be replaces with configure.

```
# change
BackboneORM.CacheSingletons.ModelCache.configure(options)

# to
BackboneORM.configure({model_cache: options})
```
