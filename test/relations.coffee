assert = require 'assert'
{connect} = require 'rethinkdb'
{schema} = require '../src'


Employee = Badge = Computer = Project = null
alice = badge = computer = project = null


describe 'References', ->
  before (done)->
    connect 'localhost', (err, con)->
      Employee = schema
        name: 'employee'
        connection: con
        relations:
          location: {rel:'location'}
        schema:
          properties:
            displayName:
              type: 'string'
            badge:
              type: 'badge'
              maxItems: 1
              minItems: 1
            computers:
              type: 'computer'

      Badge = schema
        name: 'badge'
        connection: con
        relations:
          mfgr: {rel:'manufacturer', maxItems:0, minItems:0}
          employee: {relatedName:'emp', rel:'employee', minItems:1, maxItems:1}
        schema:
          properties:
            badgeId:
              type: 'string'
            employeeId:
              type: 'employee'

      Computer = schema
        name: 'computer'
        connection: con
        schema:
          properties:
            make:
              type: 'string'
            model:
              type: 'string'
            cpus:
              type: 'int'

      Project = schema
        name: 'project'
        relations:
          employees: {minItems:0, rel:'employee'}
        schema:
          properties:
            name:
              type: 'string'
              required: true

      topsecret = Project.create name:'manhattan'
      badge = Badge.create badgeId:'a-9-b-4'
      iris = Computer.create make:'SGI', model:'Iris', cpus:16
      cray = Computer.create make:'Cray', model:'CR1', cpus:1024

      alice = Employee.create
        displayName: 'Alice Applegate'

      done()

  describe 'Relation properties', ->
    it 'should exist', ->
      assert badge.rel.mfgr == null

    it 'should require a "rel" attribute', (done)->
      Anything = schema
        name: 'anything'
        relations:
          employees: {minItems:0}
        schema:
          properties:
            name:
              type: 'string'
              required: true
      try
        a = Anything.create {}
      catch err
        assert err instanceof ReferenceError
      done()


  describe 'One-to-One', ->
    it 'should be supported', (done)->
      assert alice.doc.displayName == 'Alice Applegate'
      done()

    it 'should add a key to the rel object', (done)->
      #console.log badge.rel.mfgr
      done()

    it 'should add a given key to the rel object', (done)->
      assert badge.rel.emp == null
      badge.rel.emp = alice
      assert badge.rel.emp is alice
      done()
