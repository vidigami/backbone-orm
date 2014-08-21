assert = assert or require?('chai').assert

BackboneORM = window?.BackboneORM; try BackboneORM or= require?('backbone-orm') catch; try BackboneORM or= require?('../../../../backbone-orm')
{_, JSONUtils} = BackboneORM
URL = BackboneORM.modules.url

VALUES =
  date: new Date()
  string: "日本語"
  number: 123456789
  number_string: "123456789"
  number2: 123456789e21
  number2_string: '123456789e21'
  object:
    date: new Date()
    string: "日本語"
    number: 123456789
  array: [new Date(), "日本語", 123456789e21, "123456789e21"]

MODEL_URL = 'https://things/1'

describe 'JSONUtils @quick @json', ->
  it 'parse maintains types correctly', (done) ->
    parsed_json = JSONUtils.parseQuery(JSONUtils.querify(VALUES))
    assert.deepEqual(parsed_json, VALUES)
    done()

  it 'querify handles control directives', (done) ->
    query = {$limit: 1, $one: true, $hello: 'abc', $sort: ['name'], $id: {$in: [1, '2']}}
    parsed_query = {$limit: 1, $one: true, $hello: 'abc', $sort: ['name'], $id: {$in: [1, '2']}}

    assert.deepEqual(JSONUtils.parseQuery(JSONUtils.querify(query)), parsed_query, 'matches without extra JSON operations')
    assert.deepEqual(JSONUtils.parseQuery(JSON.parse(JSON.stringify(JSONUtils.querify(query)))), parsed_query, 'matches with extra JSON operations')
    done()

  describe 'Strict JSON in URL', ->
    it 'handles unicode strings', (done) ->
      KEY = 'string'
      url_parts = URL.parse(MODEL_URL, true); _.extend(url_parts.query, JSONUtils.querify(_.pick(VALUES, KEY))); url = URL.format(url_parts)
      assert.equal(url, "#{MODEL_URL}?#{KEY}=#{encodeURIComponent('"' + VALUES[KEY] + '"')}", 'URL has string')
      url_parts = URL.parse(url, true)
      assert.equal(JSONUtils.parseQuery(url_parts.query)[KEY], VALUES[KEY], 'Same type returned')
      done()

    it 'handles number strings', (done) ->
      KEY = 'number_string'
      url_parts = URL.parse(MODEL_URL, true); _.extend(url_parts.query, JSONUtils.querify(_.pick(VALUES, KEY))); url = URL.format(url_parts)
      assert.equal(url, "#{MODEL_URL}?#{KEY}=#{encodeURIComponent('"' + VALUES[KEY] + '"')}", 'URL has string')
      url_parts = URL.parse(url, true)
      assert.equal(JSONUtils.parseQuery(url_parts.query)[KEY], VALUES[KEY], 'Same type returned')
      done()

    it 'handles numbers', (done) ->
      KEY = 'number'
      url_parts = URL.parse(MODEL_URL, true); _.extend(url_parts.query, JSONUtils.querify(_.pick(VALUES, KEY))); url = URL.format(url_parts)
      assert.equal(url, "#{MODEL_URL}?#{KEY}=#{encodeURIComponent(VALUES[KEY])}", 'URL has number')
      url_parts = URL.parse(url, true)
      assert.equal(JSONUtils.parseQuery(url_parts.query)[KEY], VALUES[KEY], 'Same type returned')
      done()
