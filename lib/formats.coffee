{getDate, walk, objectIDToString} = require './util'
_ = require 'lodash'

mapOp =
  n: 'noop'
  i: 'insert'
  u: 'update'
  r: 'remove'

mapOrigin =
  p: 'payload'
  ep: 'end payload'
  d: 'delta'

# formats can return an Object or an Array
# if it's an array, the elements should be sent as separate events
module.exports =

  # raw data from the oplog
  raw: (data) -> data

  # something a bit more readable, but preserving the original data
  pretty: (data) ->

    # convert ObjectIDs to strings
    data = walk data, objectIDToString

    timestamp: getDate data.ts
    operation: mapOp[data.op] or data.op
    namespace: data.ns
    operationId: data.h
    targetId: data.o2?._id or data.o?._id
    criteria: data.o2 if data.o2
    data: data.o

  # restructure all ops to look like updates
  normal: (data) ->

    # convert ObjectIDs to strings
    data = walk data, objectIDToString

    targetId = (data.o2?._id or data.o?._id)
    delete data.o._id if data.o

    switch data.op
      when 'i'
        oplist = [
          operation: 'set'
          _id: targetId
          path: '.'
          data: data.o
        ]

      when 'u'

        # if it's a simple update: {name: 'Bob'}
        if (k for k of data.o when k[0] isnt '$').length > 0
          oplist = [
            operation: 'set'
            _id: targetId
            path: '.'
            data: data.o
          ]

        # or a complex one: {'$set': {name: 'Bob'}}
        else
          oplist = []
          for op, args of data.o
            operation = op.slice 1
            for path, value of args
              oplist.push
                operation: operation
                _id: targetId
                path: path
                data: value

      when 'd'
        oplist = [
          operation: 'unset'
          _id: targetId
          path: '.'
        ]

    ops = for op in oplist
      base =
        origin: mapOrigin[data.t]
        timestamp: getDate data.ts
        namespace: data.ns
        operationId: data.h

      _.merge op, base

    return ops
