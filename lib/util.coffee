{Timestamp} = require 'mongodb'

module.exports = util =

  getType: (obj) ->
    ptype = Object.prototype.toString.call(obj).slice 8, -1
    if ptype is 'Object'
      return obj.constructor.name.toString()
    else
      return ptype

  # converts from js Date to oplog Timestamp
  getTimestamp: (date) ->
    date ||= new Date()
    time = Math.floor(date.getTime() / 1000)
    new Timestamp 0, time

  # converts from oplog Timestamp to js Date
  getDate: (timestamp) ->
    new Date timestamp.high_ * 1000

  walk: (data, fn) ->
    dataType = util.getType(data)
    switch dataType
      when 'Array'
        util.walk(d, fn) for d in data
      when 'Object'
        result = {}
        for k, v of data
          result[k] = util.walk(v, fn)
        result
      else
        fn(data)

  convertObjectID: (data) ->
    if util.getType(data) is 'ObjectID'
      return data.toString()
    else
      return data
