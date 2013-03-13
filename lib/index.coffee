inflection = require 'inflection'

# create and return a riak connection
exports.connection = ->
  null


# add a plugin for all schemas
exports.plugin = ->
  null


connectionEvents =
  connecting: 1
  connected: 2
  open: 3
  disconnecting: 4
  disconnected: 5
  close: 6
  reconnected: 7
  error: 8


nativeTypes = [
  Array
  Boolean
  Date
  Number
  Object
  String
  ]


exports.registry = registry = {}


exports.BaseSchema = class BaseSchema
  @create: (props)->
    inst = new @
    inst._meta = @_meta
    inst._vclock = null

    for key, attr of @_attributes
      inst[key] = attr.default
    inst._paths = keys = Object.keys @_attributes

    for key, value of props when key in keys
      inst[key] = value

    inst

  @get: (key, callback)->
    self = @
    con = @_meta.connection
    if not con
      return callback 'not connected'
    con.get {bucket:@_meta.bucket, key:key}, (response)->
      if not response
        callback 'not found'
      else
        props = JSON.parse response.content[0].value
        vclock = response.vclock.toString 'base64'
        inst = self.create props
        inst.vclock = vclock
        callback null, inst

  toJSON: ->
    data = {}
    for key in @_paths
      data[key] = @[key]
    data

  save: (options, callback)->
    con = @_meta.connection
    if not con
      return callback 'not connected'

    obj =
      bucket: @_meta.bucket
      content:
        content_type: 'application/json'
        value: JSON.stringify @

    con.put obj, (response)->
      if response.errmsg
        return callback response.errmsg+''
      callback null, response.key+''


normalizeAttr = (attr)->
  typ = nativeTypes.filter ((t)-> attr == t)
  if typ.length
    attr = {type:typ[0]}
  if not attr.default
    attr.default = null
  attr


exports.schema = (defn)->
  defn = defn or {}
  name = defn.name

  if not name
    throw new TypeError 'Schema name required'

  props = defn.properties or {}
  methods = defn.methods or {}
  statics = defn.statics or {}
  attrs = defn.attributes or {}
  bucket = defn.bucket
  bucket = inflection.pluralize name.toLowerCase() if not bucket

  # TODO: virtuals
  # TODO: middleware
  # TODO: plugins

  class Schema extends BaseSchema
    @_meta:
      connection: defn.connection or null
      bucket: bucket

    @_attributes: {}


  for key, value of statics
    Schema[key] = value

  for key, value of methods
    Schema.prototype[key] = value

  for key, value of attrs
    Schema._attributes[key] = normalizeAttr value

  Schema._name = defn.name
  registry[defn.name] = Schema
  Schema
