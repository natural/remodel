

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


exports.BaseSchema = class BaseSchema
  @_registry = {}

  @create: (props, callback)->
    inst = new @
    for key, attr of @_attributes
      inst[key] = attr.default
    keys = Object.keys @_attributes
    for key, value of props when key in keys
      inst[key] = value
    callback null, inst

  save: (options, callback)->
    null


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

  # TODO: virtuals
  # TODO: middleware
  # TODO: plugins

  class Schema extends BaseSchema
    @_attributes: {}

  for key, value of statics
    Schema[key] = value

  for key, value of methods
    Schema.prototype[key] = value

  for key, value of attrs
    Schema._attributes[key] = normalizeAttr value

  Schema._name = defn.name
  Schema._registry[defn.name] = Schema
  Schema
