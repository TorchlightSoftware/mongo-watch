{Server, Db} = require 'mongodb'

module.exports = ({db, host, port, dbOpts}, done) ->
  client = new Db db, new Server(host, port, {native_parser: true}), dbOpts

  client.open (err) ->
    done err, client
