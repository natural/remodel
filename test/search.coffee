assert = require 'assert'
zukai = require '../lib'
riakpbc = require 'riakpbc'

Model = instance = null
instances = {}


describe 'Search', ->
  describe 'basic query', ->
    it 'should return expected results', (done)->
      Model = zukai.schema
        name: 'search-check'
        connection: riakpbc.createClient()
        properties:
          name:
            type: 'string'
          age:
            type: 'number'

      # this should turn into an 'ensure index' method
      # on models.
      request =
        bucket: Model.bucket
        props:
          precommit: [
            mod: 'riak_search_kv_hook'
            fun: 'precommit'
            ]

      Model.connection.setBucket request, (reply)->
        assert not reply.errmsg

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
