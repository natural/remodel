assert = require 'assert'
zukai = require '../lib'
riakpbc = require 'riakpbc'

Model = instance = null
instances = {}


describe 'Map Reduce', ->
  describe 'basic query', ->
    it 'should return expected results', (done)->
      Model = zukai.schema
        name: 'mapred-check'
        connection: riakpbc.createClient()
        properties:
          name:
            type: 'string'
          age:
            type: 'number'

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

          f = (value)->
            [[value.bucket, value.key]]

          Model.mapred {map:f}, (err, res)->
            if err
              console.log err
            assert not err
            #console.log 'alice', instance.key
            #console.log 'bob', inst.key
            #console.log 'mapred cb', err, res

            instance.del ->
              inst.del done
