assert = require 'assert'
{isEqual} = require 'underscore'
{walk} = require '../lib'


describe 'Utilities', ->
  describe 'walk function', ->
    it 'should call the callback for every key', ->
      keys = []
      values = []
      map = {a:11, b:22, c:33}

      walk map, (k, v)->
        keys.push k
        values.push v

      assert isEqual keys, (k for k, v of map)
      assert isEqual values, (v for k, v of map)

    it 'should call the callback when predicate is true', ->
      keys = []
      values = []
      map = {a:11, b:22, c:33}
      cb = (k, v)->
        keys.push k
        values.push v
      pred = (k, v)->
        k == 'c'
      walk map, cb, pred

      assert isEqual keys, ['c']
      assert isEqual values, [map.c]

    it 'should never call the callback when predicate is false', ->
      keys = []
      values = []
      map = {a:11, b:22, c:33}
      cb = (k, v)->
        keys.push k
        values.push v
      pred = (k, v)->
        false
      walk map, cb, pred

      assert isEqual keys, []
      assert isEqual values, []

    it 'should recurse into nested objects', ->
      keys = []
      values = []

      map =
        d: 44
        e: 55
        f: 66
        nested:
          g: 77
          h: 88
          i: 99
          nested:
            j: 1010
            k: 1111
            l: 1212

      cb = (k, v)->
        if typeof v == 'number'
          keys.push k
          values.push v

      walk map, cb
      assert keys.length == values.length == 9
