assert = require 'assert'
{connect} = require 'rethinkdb'
{schema} = require '../lib'


Employee = Badge = Computer = Project = null
employee = badge = computer = project = null


describe 'References', ->
  before (done)->
    connect 'localhost', (err, con)->
      Employee = schema
        name: 'employee'
        connection: con
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

      badge = Badge.create badgeId:'a-9-b-4'
      iris = Computer.create make:'SGI', model:'Iris', cpus:16
      cray = Computer.create make:'Cray', model:'CR1', cpus:1024

      employee = Employee.create
        displayName: 'Alice Applegate'
        badge: badge.doc
        computers: [iris, cray]

      done()

  describe 'One-to-One', ->
    it 'should be supported', (done)->
      assert employee.doc.displayName == 'Alice Applegate'
      assert badge.doc.badgeId == 'a-9-b-4'
      assert employee.doc.badge == badge.doc
      assert employee.doc.badge.badgeId == 'a-9-b-4'
      done()
