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
      assert Foo
      assert Foo._name == 'foo'

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
            @_meta
      x = Bore.create {}
      assert x.check()


    it 'should provide a default bucket name', ->
      Score = zukai.schema
        name: 'score'
      assert Score._meta.bucket == 'scores'

    it 'should allow a provided bucket name', ->
      bucket = 'the_doors_suck'
      Door = zukai.schema
        name: 'door'
        bucket: bucket
      assert Door._meta.bucket == bucket


  describe 'saving model objects', ->
    it 'should indicate an error when connection is missing', (done)->
      Core = zukai.schema
        name: 'core'
        attributes:
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
        attributes:
          name: String
      c = Lore.create name:'loar'
      assert c
      c.save {}, (err, doc)->
        assert not err
        assert doc
        done()

  describe 'getting model objects by key', ->
    it 'should work when connection is present', (done)->
      Gore = zukai.schema
        name: 'gore'
        connection: riakpbc.createClient()
        attributes:
          name: String
      c = Gore.create name:'goar'
      c.save {}, (err, key)->
        assert not err
        assert key
        Gore.get key, (err, doc)->
          assert not err
          assert doc
          assert doc.name == 'goar'
          done()
