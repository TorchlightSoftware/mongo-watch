{Server, Db} = require 'mongodb'
{getTimestamp} = require './util'

existingStream = null

module.exports = ({host, port}, done) ->
  if existingStream
    return done null, existingStream

  else
    client = new Db 'local', new Server(host, port, {native_parser: true}), {w: 0}

    client.open (err) ->
      return done err if err

      client.collection 'oplog.rs', (err, oplog) ->
        return done err if err

        connOpts =
          tailable: true
          awaitdata: true
          oplogreplay: true # does this do anything?
          numberOfRetries: -1

        currentTime = getTimestamp()

        cursor = oplog.find {ts: {$gte: currentTime}}, connOpts
        stream = cursor.stream()
        existingStream = stream

        done null, stream
