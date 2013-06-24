{Timestamp} = require 'mongodb'

module.exports = util =

  getType: (obj) -> Object.prototype.toString.call(obj).slice 8, -1

  # converts from js Date to oplog Timestamp
  getTimestamp: (date) ->
    date ||= new Date()
    time = Math.floor(date.getTime() / 1000)
    new Timestamp 0, time

  # converts from oplog Timestamp to js Date
  getDate: (timestamp) ->
    new Date timestamp.high_ * 1000

  walk: (data, fn) ->
    switch util.getType(data)
      when 'Array'
        util.walk(d, fn) for d in data
      when 'Object'
        result = {}
        for k, v of data
          result[k] = util.walk(v, fn)
        result
      else
        fn(data)
