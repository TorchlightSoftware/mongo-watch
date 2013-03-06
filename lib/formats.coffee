{getDate} = require './util'

mapOp =
  n: 'noop'
  i: 'insert'
  u: 'update'
  r: 'remove'

module.exports =

  # raw data from the oplog
  raw: (data) -> data

  # something a bit more readable, but preserving the original data
  pretty: (data) ->
    timestamp: getDate data.ts
    operation: mapOp[data.op] or data.op
    namespace: data.ns
    operationId: data.h.toString()
    targetId: data.o2?._id or data.o?._id
    criteria: data.o2
    data: data.o
