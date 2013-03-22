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


resolveRelations = (name, schema)->
  #console.log 'resolving schema relations', name


makeRelProp = (obj, key, schema)->
  # special case ref:'self'

  schema = {} if not schema?
  rel = schema.rel
  if not rel?
    throw new ReferenceError 'Related schema requires rel attribute'
  min = if schema.minItems? then schema.minItems else 0
  max = schema.maxItems

  cardone = (min == 0 or min == 1) and max == 1
  if max?
    cardmany = max >= 2
  else
    cardmany = true


  console.log 'makeRelProp', schema, cardone, cardmany
  val = null

  get: ->
    #console.log "get #{key}, #{obj.doc}"
    val
  set: (v)->
    #console.log "set #{key} to #{v}"
    val = v



exports.registry = registry = {}


exports.BaseSchema = class BaseSchema
  @createTable: (callback)->
    rdb.db(@database).tableCreate(@table).run @connection, callback

  @dropTable: (callback)->
    rdb.db(@database).tableDrop(@table).run @connection, callback

  @clearTable: (callback)->
    rdb.db(@database).table(@table).delete().run @connection, callback

  @create: (doc)->
    inst = new @
    inst.connection = @connection
    inst.database = @database
    inst.key = null
    inst.modelName = @modelName
    inst.relations = @relations
    inst.schema = @schema
    inst.table = @table

    inst.rel = rel = {}
    for key, value of @relations
      key = value.relatedName if value.relatedName
      Object.defineProperty rel, key, makeRelProp(inst, key, value)

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

    rdb.db(@database).table(@table).get(key).run con, (err, doc)->
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
    rdb.db(@database).table(@table).filter(q).run con, callback

  toJSON: ->
    @doc

  del: (callback)->
    con = @connection
    if not con
      return callback errmsg:'not connected'
    if not @key
      return callback errmsg:'no key'
    rdb.db(@database).table(@table).get(@key).delete().run con, callback

  save: (options, callback)->
    if typeof options == 'function'
      callback = options
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'
    rdb.db(@database).table(@table).insert(@doc).run con, (err, doc)->
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

  connection = defn.connection or null
  database = defn.database or 'test'
  modelName = name
  relations = defn.relations or {}
  schema = defn.schema or {}
  table = defn.table
  table = inflection.pluralize name.toLowerCase() if not table

  class Schema extends BaseSchema
    @connection: connection
    @database: database
    @modelName: modelName
    @relations: relations
    @schema: schema
    @table: table

  for key, value of (defn.statics or {})
    Schema[key] = value

  for key, value of (defn.methods or {})
    Schema.prototype[key] = value

  resolveRelations name, Schema
  registry[name] = Schema


exports.walk = walk = (obj, callback, predicate)->
  predicate = (->true) if not predicate
  for key, val of obj
    if predicate key, val
      callback key, val
      if typeof val == 'object'
        walk val, callback, predicate
