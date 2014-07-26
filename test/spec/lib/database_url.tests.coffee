assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, DatabaseURL} = BackboneORM

describe 'DatabaseURL @quick', ->
  it 'parses url (unparsed query)', (done) ->
    url = new DatabaseURL('protocol://user:password@host:80/database/model_names?query1=true&query2="bob"')
    assert.equal(url.protocol, 'protocol:')

    assert.equal(url.auth, 'user:password')
    assert.deepEqual(url.parseAuth(), {user: 'user', password: 'password'})

    assert.equal(url.hostname, 'host')
    assert.equal(url.host, 'host:80')
    assert.equal(url.port, 80)

    assert.equal(url.database, 'database')
    assert.equal(url.table, 'model_names')

    assert.equal(url.search, '?query1=true&query2=' + encodeURIComponent('"bob"'))
    assert.equal(url.query, 'query1=true&query2='  + encodeURIComponent('"bob"'))

    assert.equal(url.modelName(), 'ModelName')
    done()

  it 'parses url (parsed query)', (done) ->
    url = new DatabaseURL('protocol://user:password@host:80/database/model_names?query1=true&query2="bob"', true)
    assert.equal(url.protocol, 'protocol:')

    assert.equal(url.auth, 'user:password')
    assert.deepEqual(url.parseAuth(), {user: 'user', password: 'password'})

    assert.equal(url.hostname, 'host')
    assert.equal(url.host, 'host:80')
    assert.equal(url.port, 80)

    assert.equal(url.database, 'database')
    assert.equal(url.table, 'model_names')

    assert.equal(url.search, '?query1=true&query2=' + encodeURIComponent('"bob"'))
    assert.deepEqual(url.query, {query1: 'true', query2: '"bob"'})

    assert.equal(url.modelName(), 'ModelName')
    done()

  it 'parses url (comma-delimited)', (done) ->
    url = new DatabaseURL('protocol://user:password@host1:81,host2:82,host3:83/database/model_names?query1=true&query2="bob"')
    assert.equal(url.protocol, 'protocol:')

    assert.equal(url.auth, 'user:password')
    assert.deepEqual(url.parseAuth(), {user: 'user', password: 'password'})

    assert.deepEqual(url.hosts, [{host: 'host1', hostname: 'host1:81', port: '81'}, {host: 'host2', hostname: 'host2:82', port: '82'}, {host: 'host3', hostname: 'host3:83', port: '83'}])
    assert.ok(_.isUndefined(url.hostname))
    assert.ok(_.isUndefined(url.host))
    assert.ok(_.isUndefined(url.port))

    assert.equal(url.database, 'database')
    assert.equal(url.table, 'model_names')

    assert.equal(url.search, '?query1=true&query2=' + encodeURIComponent('"bob"'))
    assert.equal(url.query, 'query1=true&query2='  + encodeURIComponent('"bob"'))

    assert.equal(url.modelName(), 'ModelName')
    done()

  it 'formats url (unparsed query)', (done) ->
    url = new DatabaseURL('protocol://user:password@host:80/database/model_names?query1=true&query2="bob"')

    url.search = '?query1=true'
    url_string = url.format()
    assert.equal(url_string, 'protocol://user:password@host:80/database/model_names?query1=true')
    done()

  it 'formats url (parsed query)', (done) ->
    url = new DatabaseURL('protocol://user:password@host:80/database/model_names?query1=true&query2="bob"', true)

    delete url.search; delete url.query.query2
    url_string = url.format()
    assert.equal(url_string, 'protocol://user:password@host:80/database/model_names?query1=true')
    done()

  it 'formats url (without table)', (done) ->
    url = new DatabaseURL('protocol://user:password@host:80/database/model_names?query1=true&query2="bob"', true)

    url_string = url.format({exclude_table: true})
    assert.equal(url_string, 'protocol://user:password@host:80/database?query1=true&query2=' + encodeURIComponent('"bob"'))

    delete url.table
    url_string = url.format()
    assert.equal(url_string, 'protocol://user:password@host:80/database?query1=true&query2=' + encodeURIComponent('"bob"'))

    done()

  it 'formats url (without query)', (done) ->
    url = new DatabaseURL('protocol://user:password@host:80/database/model_names?query1=true&query2="bob"', true)

    url_string = url.format({exclude_search: true})
    assert.equal(url_string, 'protocol://user:password@host:80/database/model_names')

    url_string = url.format({exclude_query: true})
    assert.equal(url_string, 'protocol://user:password@host:80/database/model_names')

    delete url.search; delete url.query
    url_string = url.format()
    assert.equal(url_string, 'protocol://user:password@host:80/database/model_names')

    done()

  it 'formats url (comma-delimited)', (done) ->
    url = new DatabaseURL('protocol://user:password@host1:81,host2:82,host3:83/database/model_names?query1=true&query2="bob"')

    url_string = url.format({exclude_table: true})
    assert.equal(url_string, 'protocol://user:password@host1:81,host2:82,host3:83/database?query1=true&query2=' + encodeURIComponent('"bob"'))

    delete url.table
    url_string = url.format()
    assert.equal(url_string, 'protocol://user:password@host1:81,host2:82,host3:83/database?query1=true&query2=' + encodeURIComponent('"bob"'))

    done()
