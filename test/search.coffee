assert = require 'assert'
zukai = require '../lib'
riakpbc = require 'riakpbc'

Model = instance = null
instances = {}


describe 'Search', ->
  describe 'basic query', ->
    it 'should return expected results', (done)->
      if process.env.TRAVIS
        return done()

      Model = zukai.schema
        name: 'search-check'
        connection: riakpbc.createClient()
        fields:
          name: String
          age: Number

      instance = Model.create name:'alice', age:21
      assert instance.doc.name == 'alice'

      instance.save (err, k)->
        assert k
        instances[k] = instance

        inst = Model.create name:'bob', age:34
        assert inst.doc.name == 'bob'
        inst.save (err, k)->
          assert k
          instances[k] = inst

          Model.search 'name:alice', (err, res)->
            if err
              console.log err
            assert not err
            #console.log res

            instance.del ->
              inst.del done
