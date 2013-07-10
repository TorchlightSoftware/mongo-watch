{Timestamp} = require 'mongodb'
_ = require 'lodash'
logger = require 'ale'
{ObjectID} = require 'mongodb'

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

  objectIDToString: (data) ->
    if util.getType(data) is 'ObjectID'
      return data.toString()
    else
      return data

  stringToObjectID: (data) ->
    if util.getType(data) is 'String' and data.match /^[a-f0-9]{24}$/
      return new ObjectID(data)
    else
      return data

  lMissing: (target, test) ->
    return [] unless util.getType(target) is 'Array' and util.getType(test) is 'Array'
    _.filter target, (t) -> t not in test

  rMissing: (test, target) ->
    util.lMissing test, target

  addTo: (arr, item_s) ->
    if util.getType(item_s) is 'Array'
      arr.push item_s...
    else
      arr.push item_s
    arr

  sample: (emitter, event, n, done) ->
    done ?= ->

    results = []
    placeCb = ->
      if n-- > 0
        emitter.once event, (args...) ->
          results.push args
          placeCb()
      else
        done null, results

    placeCb()
