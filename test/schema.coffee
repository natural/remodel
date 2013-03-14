assert = require 'assert'
zukai = require '../lib'
riakpbc = require 'riakpbc'

describe 'Schema', ->
  describe 'constructor', ->
    it 'should require a name', ->
      try
        zukai.schema()
        assert 0
      catch err
        assert err.message == 'Schema name required'

    it 'should function with only a name key', ->
      Foo = zukai.schema name:'foo'
      assert Foo.modelName == 'foo'

    it 'should register the schema', ->
      'foo' in zukai.registry

  describe 'static methods', ->
    it 'should have a known static method', ->
      Bar = zukai.schema name:'bar'
      assert Bar.create?

    it 'should have a specified static method', ->
      Other = zukai.schema
        name: 'other'
        statics:
          foo: ->
      assert Other.foo

    it 'should have a specified static with correct `this`', ->
      Other = zukai.schema
        name: 'other'
        statics:
          foo: ->
            @
      assert Other.foo() == Other

  describe 'schema instance', ->
    it 'should have a known method', ->
      Some = zukai.schema
        name: 'Some'
      x = new Some
      assert x.save

    it 'should have a specified method', ->
      Again = zukai.schema
        name: 'Again'
        methods:
          check: ->
      x = new Again
      assert x.check

    it 'should have a specified method with correct `this`', ->
      More = zukai.schema
        name: 'More'
        methods:
          yup: ->
            @
      x = new More
      assert x.yup() == x

    it 'should have a method that can access the class', ->
      Bore = zukai.schema
        name: 'Bore'
        connection: 3
        methods:
          check: ->
            @bucket
      x = Bore.create {}
      assert x.check()


    it 'should provide a default bucket name', ->
      Score = zukai.schema
        name: 'score'
      assert Score.bucket == 'scores'

    it 'should allow a provided bucket name', ->
      bucket = 'the_doors_suck'
      Door = zukai.schema
        name: 'door'
        bucket: bucket
      assert Door.bucket == bucket


  describe 'saving model objects', ->
    it 'should indicate an error when connection is missing', (done)->
      Core = zukai.schema
        name: 'core'
        fields:
          name: String
      c = Core.create name:'coar'
      assert c
      c.save {}, (err, doc)->
        assert err
        assert not doc
        done()


    it 'should work when connection is present', (done)->
      Lore = zukai.schema
        name: 'lore'
        connection: riakpbc.createClient()
        fields:
          name: String
      c = Lore.create name:'loar'
      assert c
      c.save {}, (err, doc)->
        assert not err
        assert doc
        done()

  describe 'working with model objects by key', ->
    key = model = null
    Gore = zukai.schema
      name: 'gore'
      connection: riakpbc.createClient()
      fields:
        name: String

    it 'should allow Schema.get', (done)->
      model = Gore.create name:'goar'
      model.save {}, (err, k)->
        assert not err
        assert k
        Gore.get k, (err, doc)->
          assert not err
          assert doc
          assert doc.doc.name == 'goar'
          key = k
          done()

    it 'should allow model.del', (done)->
      model.del (err, key)->
        assert not err
        Gore.get key, (err, doc)->
          assert not err
          assert not doc
          done()
