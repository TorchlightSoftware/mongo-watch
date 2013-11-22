{Server, Db} = require 'mongodb'

module.exports = ({db, host, port, dbOpts, username, password}, done) ->
  client = new Db db, new Server(host, port, {native_parser: true}), dbOpts

  client.open (err) ->
    return done(err) if err

    # authenticate if credentials were provided
    if username? or password?
      client.authenticate username, password, (err, result) ->
        done err, client

    else
      done err, client
