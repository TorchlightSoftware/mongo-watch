{Timestamp} = require 'mongodb'

module.exports =

  # converts from js Date to oplog Timestamp
  getTimestamp: (date) ->
    date ||= new Date()
    time = Math.floor(date.getTime() / 1000)
    new Timestamp 0, time

  # converts from oplog Timestamp to js Date
  getDate: (timestamp) ->
    new Date timestamp.high_ * 1000
