[![Build Status](https://secure.travis-ci.org/vidigami/backbone-orm.png)](http://travis-ci.org/vidigami/backbone-orm#master)

![logo](https://github.com/vidigami/backbone-orm/raw/master/media/logo.png)

BackboneORM was designed to provide a consistent, polystore ORM across Node.js and the browser.

It was inspired by other great software and provides:

* Node.js-style callbacks and streams for a familiar asynchronous programming style
* MongoDB-like query language to easily slice-and-dice your data
* a REST controller enabling browser search bar queries and an optional paging format like CouchDB

Other great things:

* it provides a JSON-rendering DSL
* it solves the dreaded Node.js circular dependencies problem for related models
* it is compatible with [Knockback.js](http://kmalakoff.github.io/knockback/)
* it parses ISO8601 dates automatically
* BackboneMongo provides a CouchDB-like '_rev' versioning solution
* BackboneREST provides authorization middleware hooks and emits REST events

#### Modules

Out of the box, BackboneORM comes packaged with a memory store. Other modules:

* [BackboneHTTP](https://github.com/vidigami/backbone-http) - remote storage over HTTP
* [BackboneMongo](https://github.com/vidigami/backbone-mongo) - MongoDB
* [BackboneSQL](https://github.com/vidigami/backbone-sql) - PostgreSQL, MySQL
* [BackboneREST](https://github.com/vidigami/backbone-rest) - Express and Restify REST endpoint generator for BackboneHTTP


#### Examples (CoffeeScript)

```coffeescript
# Find the Project with id = 123
Project.findOne {id: 123}, (err, project) ->

# Find the first Project named 'my kickass project'
Project.findOne {name: 'my kickass project'}, (err, project) ->

# Find all items with is_active = true
Project.find {is_active: true}, (err, projects) ->

# Find the items with an id of 1, 2 or 3
Project.find {id: {$in: [1, 2, 3]}}, (err, projects) ->

# A shortcut for `$in` when we're working with ids
Project.find {$ids: [1, 2, 3]}, (err, projects) ->

# Find active items in pages
Project.find {is_active: true, $limit: 10, $offset: 20}, (err, projects) ->

# Select named properties from each model
Project.find {$select: ['created_at', 'name']}, (err, array_of_json) ->

# Select values in the specified order
Project.find {$values: ['created_at', 'status']}, (err, array_of_arrays) ->

# Find active items in pages using cursor syntax (Models or JSON)
Project.cursor({is_active: true}).limit(10).offset(20).toModels (err, projects) ->
Project.cursor({is_active: true}).limit(10).offset(20).toJSON (err, projects_json) ->

# Find completed tasks in a project
project.cursor('tasks', {status: 'completed'}).sort('name').toModels (err, tasks) ->

# Iterate through all items with is_active = true in batches of 200
Project.each {is_active: true, $each: {fetch: 200}},
  ((project, callback) -> console.log "project: #{project.get('name')}"; callback()),
  (err) -> console.log 'Done'

# Stream all items with is_active = true in batches of 200
Project.stream({is_active: true, $each: {fetch: 200}})
  .pipe(new ModelStringifier())
  .on('finish', -> console.log 'Done')

# Collect the status of tasks over days
stats = []
Task.interval {$interval: {key: 'created_at', type: 'days', length: 1}},
  ((query, info, callback) ->
    histogram = new Histogram()
    Task.stream(_.extend(query, {$select: ['created_at', 'status']}))
      .pipe(histogram)
      .on('finish', -> stats.push(histogram.summary()); callback())
  ),
  (err) -> console.log 'Done'
```

#### Examples (JavaScript)

```javascript
// Find the Project with id = 123
Project.findOne({id: 123}, function(err, project) {});

// Find the first Project named 'my kickass project'
Project.findOne({name: 'my kickass project'}, function(err, project) {});

// Find all items with is_active = true
Project.find({is_active: true}, function(err, projects) {});

// Find the items with an id of 1, 2 or 3
Project.find({id: {$in: [1, 2, 3]}}, function(err, projects) {});

// A shortcut for `$in` when we're working with ids
Project.find({$ids: [1, 2, 3]}, function(err, projects) {});

// Find all items with is_active = true
Project.find({is_active: true, $limit: 10, $offset: 20}, function(err, projects) {});

// Select named properties from each model
Project.find({$select: ['created_at', 'name']}, function(err, array_of_json) {});

// Select values in the specified order
Project.find({$values: ['created_at', 'status']}, function(err, array_of_arrays) {});

// Find active items in pages using cursor syntax (Models or JSON)
Project.cursor({is_active: true}).limit(10).offset(20).toModels function(err, projects) {});
Project.cursor({is_active: true}).limit(10).offset(20).toJSON function(err, projects_json) {});

// Find completed tasks in a project sorted by name
project.cursor('tasks', {status: 'completed'}).sort('name').toModels function(err, tasks) {});

// Iterate through all items with is_active = true in batches of 200
Project.each({is_active: true, $each: {fetch: 200}},
  function(project, callback) {console.log('project: ' + project.get('name')); callback()},
  function(err) {return console.log('Done');}
);

// Stream all items with is_active = true in batches of 200
Project.stream({is_active: true, $each: {fetch: 200}})
  .pipe(new ModelStringifier())
  .on('finish', function() {return console.log('Done');});

var stats = [];
Task.interval({$interval: {key: 'created_at', type: 'days', length: 1}},
  function(query, info, callback) {
    var histogram = new Histogram()
    Task.stream(_.extend(query, {$select: ['created_at', 'status']}))
      .pipe(histogram)
      .on('finish', function() {stats.push(histogram.summary()); return callback();});
  },
  function(err) { return console.log('Done'); }
);
```


Please [checkout the website](http://vidigami.github.io/backbone-orm/) for installation instructions, examples, documentation, and community!


### For Contributors

To build the library for Node.js and browsers:

```
$ gulp build
```

Please run tests before submitting a pull request:

```
$ gulp test --quick
```

and eventually all tests:

```
$ npm test
```
