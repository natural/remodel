assert = require 'assert'
{connect} = require 'rethinkdb'
{schema} = require '../lib'


Model = null


describe 'Search', ->
  before (done)->
    connect 'localhost', (err, con)->
      assert not err

      Model = schema
        name: 'searchcheck'
        table: 'test'
        connection: con
        properties:
          name:
            type: 'string'
          age:
            type: 'number'

      Model.clearTable done

  describe 'basic query', ->
    it 'should return expected results', (done)->
      alice = Model.create name:'alice', age:21
      assert alice.doc.name == 'alice'

      alice.save (err, inst1)->
        assert inst1

        bob = Model.create name:'bob', age:34
        assert bob.doc.name == 'bob'

        bob.save (err, inst2)->
          assert inst2

          Model.search name:'bob', (err, cursor)->
            assert not err
            cursor.toArray (err, res)->
              assert res.length == 1
              done()
