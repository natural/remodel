require './Object.observe/Object.observe.poly'
inflection = require 'inflection'
jsonschema = require 'jsonschema'

# add a plugin for all schemas
exports.plugin = ->
  null


applyDefaults = (properties, doc)->
  for name, prop of properties
    if not doc[name]?
      def = prop.default
      def = def() if typeof def == 'function'
      doc[name] = def


exports.registry = registry = {}



exports.BaseSchema = class BaseSchema
  @create: (doc)->
    inst = new @
    inst.bucket = @bucket
    inst.connection = @connection
    inst.vclock = inst.key = null


    applyDefaults @properties, doc

    res = jsonschema.validate doc, properties:@properties
    if not res.length
      inst.invalid = false
      inst.doc = doc
    else
      console.log 'invalid', res
      inst.invalid = res
      inst.doc = {}

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





exports.schema = (defn)->
  defn = defn or {}
  name = defn.name

  if not name
    throw new TypeError 'Schema name required'

  props = defn.properties or {}
  methods = defn.methods or {}
  statics = defn.statics or {}

  bucket = defn.bucket
  bucket = inflection.pluralize name.toLowerCase() if not bucket

  class Schema extends BaseSchema
    @connection: defn.connection or null
    @bucket: bucket
    @properties: defn.properties
    @modelName = name

  for key, value of statics
    Schema[key] = value

  for key, value of methods
    Schema.prototype[key] = value

  registry[name] = Schema
