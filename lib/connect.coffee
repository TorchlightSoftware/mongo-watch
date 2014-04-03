{Server, Db} = require 'mongodb'

module.exports = ({db, host, port, dbOpts, username, password}, done) ->
	# Create a collection of DB options that includes native_parser without
	# modifying the collection that the caller provided
	finalDbOpts = {native_parser: true}
	for key in dbOpts
		finalDbOpts[key] = dbOpts[key]
	
  client = new Db db, new Server(host, port), finalDbOpts

  client.open (err) ->
    return done(err) if err

    # authenticate if credentials were provided
    if username? or password?
      client.authenticate username, password, (err, result) ->
        done err, client

    else
      done err, client
