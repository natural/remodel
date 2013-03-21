inflection = require 'inflection'
jsonschema = require 'jsonschema'
rdb = require 'rethinkdb'
observe = require './Object.observe/Object.observe.poly'


# add a plugin for all schemas
exports.plugin = ->
  null


applyDefaults = (schema, doc)->
  for name, prop of schema.properties
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
    inst.db = @db
    inst.connection = @connection
    inst.key = null

    applyDefaults @schema, doc

    res = jsonschema.validate doc, @schema
    if res.errors.length
      inst.invalid = res
      inst.doc = {}
    else
      inst.invalid = false
      inst.doc = doc

    inst

  @get: (key, callback)->
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'

    rdb.db(@db).table(@table).get(key).run con, (err, doc)->
      if err
        return callback err
      if not doc
        return callback null, null
      callback null, self.create doc

  @search: (options, callback)->
    con = @connection
    if not con
      return callback errmsg:'not connected'
    q = if options.q then options.q else options
    rdb.db(@db).table(@table).filter(q).run con, callback

  toJSON: ->
    @doc

  del: (callback)->
    con = @connection
    if not con
      return callback errmsg:'not connected'
    if not @key
      return callback errmsg:'no key'
    rdb.db(@db).table(@table).get(@key).delete().run con, callback

  save: (options, callback)->
    if typeof options == 'function'
      callback = options
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'
    rdb.db(@db).table(@table).insert(@doc).run con, (err, doc)->
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
  methods = defn.methods or {}
  statics = defn.statics or {}
  connection = defn.connection or null
  schema = defn.schema or {}

  table = defn.table
  table = inflection.pluralize name.toLowerCase() if not table

  class Schema extends BaseSchema
    @connection: connection
    @table: table
    @db: db
    @schema: schema
    @modelName = name

  for key, value of statics
    Schema[key] = value

  for key, value of methods
    Schema.prototype[key] = value

  registry[name] = Schema


exports.walk = walk = (obj, callback, predicate)->
  predicate = (->true) if not predicate
  for key, val of obj
    if predicate key, val
      callback key, val
      if typeof val == 'object'
        walk val, callback, predicate
