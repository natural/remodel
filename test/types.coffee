assert = require 'assert'
zukai = require '../lib'
riakpbc = require 'riakpbc'


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
