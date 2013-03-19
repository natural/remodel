inflection = require 'inflection'
jsonschema = require 'jsonschema'
rdb = require 'rethinkdb'
observe = require './Object.observe/Object.observe.poly'


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
  @createTable: (callback)->
    rdb.db(@db).tableCreate(@table).run @connection, callback

  @dropTable: (callback)->
    rdb.db(@db).tableDrop(@table).run @connection, callback

  @clearTable: (callback)->
    rdb.db(@db).table(@table).delete().run @connection, callback

  @create: (doc)->
    inst = new @
    inst.table = @table
    inst.connection = @connection
    inst.vclock = inst.key = null

    applyDefaults @properties, doc

    res = jsonschema.validate doc, properties:@properties
    if not res.length
      inst.invalid = false
      inst.doc = doc
    else
      inst.invalid = res
      inst.doc = {}

    inst

  @get: (key, callback)->
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'

    rdb.table(@table).get(key).run con, (err, doc)->
      if err
        return callback err
      if not doc
        return callback null, null
      callback null, self.create doc

  @search: (options, callback)->
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'
    q = if options.q then options.q else options
    rdb.table(@table).filter(q).run con, callback

  toJSON: ->
    @doc

  del: (callback)->
    con = @connection
    if not con
      return callback errmsg:'not connected'
    if not @key
      return callback errmsg:'no key'
    rdb.table(@table).get(@key).delete().run con, callback

  save: (options, callback)->
    if typeof options == 'function'
      callback = options
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'
    rdb.table(@table).insert(@doc).run con, (err, doc)->
      if err
        return callback err
      key = doc.generated_keys[0]
      self.key = key
      return callback null, self


exports.schema = (defn)->
  defn = defn or {}
  name = defn.name

  if not name
    throw new TypeError 'Schema name required'

  db = defn.db or 'test'
  props = defn.properties or {}
  methods = defn.methods or {}
  statics = defn.statics or {}
  connection = defn.connection or null
  properties = defn.properties or {}

  table = defn.table
  table = inflection.pluralize name.toLowerCase() if not table

  class Schema extends BaseSchema
    @connection: connection
    @table: table
    @db: db
    @properties: properties
    @modelName = name

  for key, value of statics
    Schema[key] = value

  for key, value of methods
    Schema.prototype[key] = value

  registry[name] = Schema
