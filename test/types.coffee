_ = require 'underscore'
assert = require 'assert'
riakpbc = require 'riakpbc'

zukai = require '../lib'


describe 'Types', ->
  describe 'Number', ->
    it 'should be allowed as a field type', ->
      Berry = zukai.schema
        name: 'berry'
        properties:
          jinx:
            type: 'number'
            default: 3
      a = Berry.create jinx:4
      assert a.doc.jinx == 4

    it 'should use the default value when not specified', ->
      Berry = zukai.schema
        name: 'berry'
        properties:
          jinx:
            type: 'number'
            default: 3
      a = Berry.create {}
      assert a.doc.jinx == 3

    it 'should use the default function when not specified', ->
      Berry = zukai.schema
        name: 'berry'
        properties:
          jinx:
            type: 'number'
            default: ->123
      a = Berry.create {}
      assert a.doc.jinx == 123


  describe 'String', ->
    it 'should be allowed as a field type', ->
      Dish = zukai.schema
        name: 'dish'
        properties:
          kind:
            type: 'string'
            default: 'cup'
      a = Dish.create kind:'plate'
      assert a.doc.kind == 'plate'

    it 'should use the default value when not specified', ->
      Dish = zukai.schema
        name: 'dish'
        properties:
          kind:
            type: 'string'
            default: 'cup'
      a = Dish.create {}
      assert a.doc.kind == 'cup'

    it 'should use the default function when not specified', ->
      Dish = zukai.schema
        name: 'dish'
        properties:
          kind:
            type: 'string'
            default: ->'plate'
      a = Dish.create {}
      assert a.doc.kind == 'plate'


  describe 'Date', ->
    it 'should be allowed as a field type', ->
      now = new Date
      Fish = zukai.schema
        name: 'fish'
        properties:
          born:
            type: 'date'
            default: null
      a = Fish.create born:now
      assert a.doc.born == now

    it 'should use the default value when not specified', ->
      sometime = new Date '1920-03-04'
      Fish = zukai.schema
        name: 'fish'
        properties:
          born:
            type: 'date'
            default: sometime
      a = Fish.create {}
      assert a.doc.born == sometime

    it 'should use the default function when not specified', (done)->
      sometime = new Date
      Fish = zukai.schema
        name: 'fish'
        properties:
          born:
            type: 'date'
            default: -> new Date

      later = ->
        a = Fish.create {}
        assert a.doc.born.getTime() > sometime.getTime()
        done()
      setTimeout later, 10


  describe 'Array', ->
    it 'should be allowed as a field type', ->
      Honey = zukai.schema
        name: 'honey'
        properties:
          hives:
            type: 'array'
            default: []
      a = Honey.create hives:[1,2,3]
      assert a.doc.hives.length == 3

    it 'should use the default value when not specified', ->
      Jam = zukai.schema
        name: 'jam'
        properties:
          sizes:
            type: 'array'
            default: [4,5,6,7]
      a = Jam.create {}
      assert _.isEqual, a.doc.sizes, [4,5,6,7]

    it 'should use the default function when not specified', ->
      Kite = zukai.schema
        name: 'kite'
        properties:
          points:
            type: 'array'
            default:->[8,9,10,11,12]
      a = Kite.create {}
      assert _.isEqual, a.doc.points, [8,9,10,11,12]
