assert = require 'assert'
{connect} = require 'rethinkdb'
{schema} = require '../lib'


Model = instance = null


describe 'Methods', ->
  describe 'create', ->
    it 'should make a new model instance', (done)->
      connect 'localhost', (err, con)->
        Model = schema
          name: 'methodcheck'
          connection: con
          properties:
            val:
              type: 'number'

        Model.createTable (err)->
          instance = Model.create val:0
          assert instance.doc.val == 0
          done()

  describe 'save when', ->
    it 'should not return an error', (done)->
      instance.save (err, inst)->
        assert inst.key == instance.key
        done()

  describe 'save after change', ->
    it 'should not return an error', (done)->
      newval = 4321
      instance.doc.val = newval
      instance.save (err, inst)->
        assert not err
        assert inst.key == instance.key

        Model.get instance.key, (err, other)->
          assert not err
          assert other.doc.val == newval
          done()

  describe 'delete', ->
    it 'should not return an error', (done)->
      instance.del (err)->
        assert not err

        Model.get instance.key, (err, other)->
          assert not err
          assert not other
          done()

  describe 'toJSON', ->
    it 'should return the document', ->
      assert instance.toJSON().val == instance.doc.val
      assert instance.toJSON() == instance.doc

  describe 'inheritance', ->
    it 'should allow methods to be replaced', (done)->
      arg1 = 1
      arg2 = 2

      Fruit = schema
        name: 'fruit'
        methods:
          del: (cb)->
            cb arg1, arg2

      grapes = Fruit.create()
      grapes.del (a, b)->
        assert a == arg1
        assert b == arg2
        done()
