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
