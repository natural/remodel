assert = require 'assert'
zukai = require '../lib'
riakpbc = require 'riakpbc'

Model = instance = null


describe 'Methods', ->
  describe 'create', ->
    it 'should make a new model instance', ->
      Model = zukai.schema
        name: 'method-check'
        connection: riakpbc.createClient()
        properties:
          val:
            type: 'number'
      instance = Model.create val:0
      assert instance.doc.val == 0

  describe 'save when', ->
    it 'should not return an error', (done)->
      instance.save (err, k)->
        assert k == instance.key
        done()

  describe 'save after change', ->
    it 'should not return an error', (done)->
      newval = 4321
      instance.doc.val = newval
      instance.save (err, k)->
        assert not err
        assert k == instance.key

        Model.get instance.key, (err, instance)->
          assert not err
          assert instance.doc.val == newval
          done()

  describe 'delete', ->
    it 'should not return an error', (done)->
      instance.del (err)->
        assert not err

        Model.get instance.key, (err, instance)->
          assert not err
          assert not instance
          done()

  describe 'toJSON', ->
    it 'should return the document', ->
      assert instance.toJSON().val == instance.doc.val
      assert instance.toJSON() == instance.doc
