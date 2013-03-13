assert = require 'assert'
zukai = require '../lib'


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
      'foo' in zukai.BaseSchema._registry

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

  describe 'instance methods', ->
    it 'should have a known instance method', ->
      Some = zukai.schema
        name: 'Some'
      x = new Some
      assert x.save

    it 'should have a specified instance method', ->
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
