{getTimestamp} = require './util'
connect = require './connect'

module.exports = ({host, port, dbOpts, username, password}, done) ->
  connect {db: 'local', host, port, dbOpts, username, password}, (err, oplogClient) =>
    return done new Error "Error connecting to database: #{err}" if err

    oplogClient.collection 'oplog.rs', (err, oplog) ->
      return done err if err

      connOpts =
        tailable: true
        awaitdata: true
        oplogReplay: true # does this do anything?
        numberOfRetries: -1

      # get a count of oplog records
      oplog.find({}, {ts: 1}).sort({$natural: -1}).limit(1).toArray (err, data) ->

        # start listening at the last record if there is one, otherwise use the javascript time
        lastOplogTime = data?[0]?.ts
        if lastOplogTime
          timeQuery = {$gt: lastOplogTime}
        else
          timeQuery = {$gte: getTimestamp()}

        cursor = oplog.find {ts: timeQuery}, connOpts
        stream = cursor.stream()

        done null, stream, oplogClient
