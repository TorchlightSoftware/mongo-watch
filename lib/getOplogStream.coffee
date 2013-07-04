{getTimestamp} = require './util'
connect = require './connect'
logger = require 'ale'

module.exports = ({host, port}, done) ->
  connect {db: 'local', host, port}, (err, oplogClient) =>
    return @error 'Error connecting to database:', err if err

    oplogClient.collection 'oplog.rs', (err, oplog) ->
      return done err if err

      connOpts =
        tailable: true
        awaitdata: true
        oplogreplay: true # does this do anything?
        numberOfRetries: -1

      # grab the last timestamp from the oplog
      oplog.find({}, {ts: 1}).sort({ts: -1}).limit(1).toArray (err, data) ->

        # start listening at the last record if there is one, otherwise use the javascript time
        currentTime = data?[0] or getTimestamp()

        cursor = oplog.find {ts: {$gte: currentTime}}, connOpts
        stream = cursor.stream()
        existingStream = stream

        done null, stream, oplogClient
