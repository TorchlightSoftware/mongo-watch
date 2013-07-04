{Server, Db} = require 'mongodb'

module.exports = ({db, host, port}, done) ->
  client = new Db db, new Server(host, port, {native_parser: true}), {w: 1}

  client.open (err) ->
    done err, client
