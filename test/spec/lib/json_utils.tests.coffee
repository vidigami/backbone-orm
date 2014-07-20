assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../backbone-orm')
{_, JSONUtils} = BackboneORM

VALUES =
  date: new Date()
  string: "日本語"
  number: 123456789
  number_string: "123456789"
  number2: 123456789e21
  number2_string: "123456789e21"
  object:
    date: new Date()
    string: "日本語"
    number: 123456789
  array: [new Date(), "日本語", 123456789e21, "123456789e21"]

_.extend(VALUES_JSON = {}, VALUES, {date: VALUES.date.toISOString(), object: _.extend({}, VALUES.object, {date: VALUES.object.date.toISOString()})})

describe 'JSONUtils', ->
  it 'parse maintains types correctly', (done) ->
    parsed_json = JSONUtils.parse(VALUES_JSON)
    assert.deepEqual(parsed_json, VALUES)
    done()

  it 'toQuery converts types correctly and parse converts it back', (done) ->
    query = JSONUtils.toQuery(VALUES)
    assert.deepEqual(query, _.extend({}, VALUES_JSON, {object: JSON.stringify(VALUES.object), array: JSON.stringify(VALUES.array)}))

    assert.deepEqual(JSONUtils.parse(JSONUtils.toQuery(query)), VALUES)
    assert.deepEqual(JSONUtils.parse(JSON.parse(JSON.stringify(JSONUtils.toQuery(query)))), VALUES)
    done()

  it 'toQuery handles control directives', (done) ->
    query = {$limit: '1', $one: 'true', $hello: 'abc', $sort: ['name'], $id: {$in: [1, '2']}}
    parsed_query = {$limit: 1, $one: true, $hello: 'abc', $sort: ['name'], $id: {$in: [1, '2']}}

    assert.deepEqual(JSONUtils.parse(JSONUtils.toQuery(query)), parsed_query)
    assert.deepEqual(JSONUtils.parse(JSON.parse(JSON.stringify(JSONUtils.toQuery(query)))), parsed_query)
    done()
