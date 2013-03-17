require './Object.observe/Object.observe.poly'
inflection = require 'inflection'


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
    inst.bucket = @bucket
    inst.connection = @connection
    inst.vclock = inst.key = null
    inst.doc = {}

    keys = Object.keys @fields

    for key in keys
      inst.doc[key] = @fields[key].default

    for key, value of props when key in keys
      inst.doc[key] = value

    inst

  @get: (key, callback)->
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'

    con.get bucket:@bucket, key:key, (response)->
      if not response
        callback errmsg:'not found'
      else
        if not response.content
          return callback null, null
        props = JSON.parse response.content[0].value
        vclock = response.vclock.toString 'base64'
        inst = self.create props
        inst.vclock = vclock
        callback null, inst

  @search: (options, callback)->
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'
    q = if options.q then options.q else options
    con.search index:self.bucket, q:q, (response)->
      if not response
        callback null, null
      else
        if response.errmsg
          callback response.errmsg+''
        else
          console.log response.docs[0]
          callback null, response

  @mapred: (options, callback)->
    if not @connection
      return callback errmsg:'not connected'

    options = options or {}
    map = options.map or (v)->
      [key:v.key]

    red = options.reduce or (values, arg)->
      values

    m0 =
      map:
        name: 'Riak.mapValuesJson'
        language: 'javascript'
        keep: true

    m1 =
      map:
        source: map.toString()
        language: 'javascript'
        keep: true

    r1 =
      reduce:
        source: red.toString()
        language: 'javascript'

    req =
      content_type: 'application/json'
      request: JSON.stringify
        inputs: @bucket
        query: [m1, m0, r1]

    @connection.mapred req, (res)->
      if res.errmsg
        callback res.errmsg+''
      else
        callback null, res

  toJSON: ->
    @doc

  del: (callback)->
    con = @connection
    if not con
      return callback errmsg:'not connected'
    if not @key
      return callback errmsg:'no key'
    con.del bucket:@bucket, key:@key, (res)->
      callback null, null

  save: (options, callback)->
    if typeof options == 'function'
      callback = options
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'
    obj =
      bucket: @bucket
      content:
        content_type: 'application/json'
        value: JSON.stringify @

    con.put obj, (response)->
      if response.errmsg
        return callback response.errmsg+''
      self.key = response.key+''
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
  attrs = defn.fields or {}
  bucket = defn.bucket
  bucket = inflection.pluralize name.toLowerCase() if not bucket

  # TODO: virtuals
  # TODO: middleware
  # TODO: plugins

  class Schema extends BaseSchema
    @connection: defn.connection or null
    @bucket: bucket
    @fields: {}
    @modelName = name

  for key, value of statics
    Schema[key] = value

  for key, value of methods
    Schema.prototype[key] = value

  for key, def of attrs
    Schema.fields[key] = normalizeAttr def

  registry[name] = Schema
  Schema
