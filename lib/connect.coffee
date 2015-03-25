{Server, Db, ReplSetServers} = require 'mongodb'
_ = require 'lodash'

module.exports = ({db, host, port, dbOpts, username, password, authdb, replicaSet}, done) ->
  _.merge {native_parser: true}, dbOpts


  if replicaSet
    replSetServers = []
    replSetServers = (new Server(num.host, num.port) for num in replicaSet)

    connection = new ReplSetServers(replSetServers)
  else
    connection = new Server(host, port)

  client = new Db(db, connection, dbOpts)

  client.open (err) ->
    return done(err) if err

    # authenticate if credentials were provided
    if username? or password?
      client.authenticate username, password, {authdb: authdb}, (err, result) ->
        done err, client

    else
      done err, client
