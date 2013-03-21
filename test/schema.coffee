assert = require 'assert'
{connect} = require 'rethinkdb'
{schema, registry} = require '../src'

Model = instance =connection = null


describe 'Schema', ->
  before (done)->
    connect 'localhost', (err, con)->
      assert not err
      assert con
      connection = con
      done()

  describe 'constructor', ->
    it 'should require a name', ->
      try
        schema()
        assert 0
      catch err
        assert err.message == 'Schema name required'

    it 'should function with only a name key', ->
      Foo = schema name:'foo'
      assert Foo.modelName == 'foo'

    it 'should register the schema', ->
      'foo' in registry

  describe 'static methods', ->
    it 'should have a known static method', ->
      Bar = schema name:'bar'
      assert Bar.create?

    it 'should have a specified static method', ->
      Other = schema
        name: 'other'
        statics:
          foo: ->
      assert Other.foo

    it 'should have a specified static with correct `this`', ->
      Other = schema
        name: 'other'
        statics:
          foo: ->
            @
      assert Other.foo() == Other

  describe 'schema instance', ->
    it 'should have a known method', ->
      Some = schema
        name: 'Some'
      x = new Some
      assert x.save

    it 'should have a specified method', ->
      Again = schema
        name: 'Again'
        methods:
          check: ->
      x = new Again
      assert x.check

    it 'should have a specified method with correct `this`', ->
      More = schema
        name: 'More'
        methods:
          yup: ->
            @
      x = new More
      assert x.yup() == x

    it 'should have a method that can access the class', ->
      Bore = schema
        name: 'Bore'
        methods:
          check: ->
            true
      x = Bore.create {}
      assert x.check()


    it 'should provide a default table name', ->
      Score = schema
        name: 'score'
      assert Score.table == 'scores'

    it 'should allow a provided table name', ->
      table = 'the_doors_suck'
      Door = schema
        name: 'door'
        table: table
      assert Door.table == table


  describe 'saving model objects', ->
    it 'should indicate an error when connection is missing', (done)->
      Core = schema
        name: 'core'
        schema:
          properties:
            name:
              type: 'string'
      c = Core.create name:'coar'
      assert c
      c.save {}, (err, doc)->
        assert err
        assert not doc
        done()


    it 'should work when connection is present', (done)->
      assert connection
      Lore = schema
        name: 'lore'
        connection: connection
        schema:
          properties:
            name:
              type: 'string'
      c = Lore.create name:'loar'
      Lore.createTable ->
        c.save {}, (err, doc)->
          assert not err
          assert doc
          done()

  describe 'working with model objects by key', ->
    it 'should allow Schema.get', (done)->
      Model = schema
        name: 'gore'
        connection: connection
        schema:
          properties:
            name:
              type: 'string'

      Model.createTable (err)->
        instance = Model.create name:'goar'
        instance.save {}, (err, inst)->
          assert not err
          assert inst
          Model.get inst.key, (err, doc)->
            assert not err
            assert doc
            assert doc.doc.name == 'goar'
            done()

    it 'should allow instance.del', (done)->
      instance.del (err, msg)->
        assert not err
        Model.get instance.key, (err, doc)->
          assert not err
          if doc
            assert doc.deleted == 1
          done()
