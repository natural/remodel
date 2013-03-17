_ = require 'underscore'
assert = require 'assert'
riakpbc = require 'riakpbc'

zukai = require '../lib'


describe 'Types', ->
  describe 'Number', ->
    it 'should be allowed as a direct field type', ->
      About = zukai.schema
        name: 'about'
        fields:
          int: Number
      a = About.create int:0
      assert a.doc.int == 0

    it 'should be allowed as a field type', ->
      Berry = zukai.schema
        name: 'berry'
        fields:
          jinx: {type: Number, default:3}
      a = Berry.create jinx:4
      assert a.doc.jinx == 4

    it 'should use the default value when not specified', ->
      Berry = zukai.schema
        name: 'berry'
        fields:
          jinx: {type: Number, default:3}
      a = Berry.create {}
      assert a.doc.jinx == 3

    it 'should use the default callable when not specified', ->
      Berry = zukai.schema
        name: 'berry'
        fields:
          jinx: {type: Number, default:->123}
      a = Berry.create {}
      assert a.doc.jinx == 123


  describe 'String', ->
    it 'should be allowed as a direct field type', ->
      Can = zukai.schema
        name: 'can'
        fields:
          lid: String
      a = Can.create lid:'loose'
      assert a.doc.lid == 'loose'

    it 'should be allowed as a field type', ->
      Dish = zukai.schema
        name: 'dish'
        fields:
          kind: {type: String, default:'cup'}
      a = Dish.create kind:'plate'
      assert a.doc.kind == 'plate'

    it 'should use the default value when not specified', ->
      Dish = zukai.schema
        name: 'dish'
        fields:
          kind: {type: String, default:'cup'}
      a = Dish.create {}
      assert a.doc.kind == 'cup'

    it 'should use the default callable when not specified', ->
      Dish = zukai.schema
        name: 'dish'
        fields:
          kind: {type: String, default:->'plate'}
      a = Dish.create {}
      assert a.doc.kind == 'plate'


  describe 'Date', ->
    it 'should be allowed as a direct field type', ->
      now = new Date
      Egg = zukai.schema
        name: 'egg'
        fields:
          laid: Date
      a = Egg.create laid:now
      assert a.doc.laid == now

    it 'should be allowed as a field type', ->
      now = new Date
      Fish = zukai.schema
        name: 'fish'
        fields:
          born: {type: Date, default:null}
      a = Fish.create born:now
      assert a.doc.born == now

    it 'should use the default value when not specified', ->
      sometime = new Date '1920-03-04'
      Fish = zukai.schema
        name: 'fish'
        fields:
          born: {type: Date, default:sometime}
      a = Fish.create {}
      assert a.doc.born == sometime

    it 'should use the default callable when not specified', (done)->
      sometime = new Date
      Fish = zukai.schema
        name: 'fish'
        fields:
          born: {type: Date, default:-> new Date}
      later = ->
        a = Fish.create {}
        assert a.doc.born.getTime() > sometime.getTime()
        done()
      setTimeout later, 10


  describe 'Array', ->
    it 'should be allowed as a direct field type', ->
      Gumdrop = zukai.schema
        name: 'gumdrop'
        fields:
          ingredients: Array
      a = Gumdrop.create ingredients:['sugar', 'dye']
      assert a.doc.ingredients.length == 2

    it 'should be allowed as a field type', ->
      Honey = zukai.schema
        name: 'honey'
        fields:
          hives: {type: Array, default:[]}
      a = Honey.create hives:[1,2,3]
      assert a.doc.hives.length == 3

    it 'should use the default value when not specified', ->
      Jam = zukai.schema
        name: 'jam'
        fields:
          sizes: {type: Array, default:[4,5,6,7]}
      a = Jam.create {}
      assert _.isEqual, a.doc.sizes, [4,5,6,7]

    it 'should use the default callable when not specified', ->
      Kite = zukai.schema
        name: 'kite'
        fields:
          points: {type: Array, default:->[8,9,10,11,12]}
      a = Kite.create {}
      assert _.isEqual, a.doc.points, [8,9,10,11,12]
