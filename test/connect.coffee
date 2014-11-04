should = require 'should'
_ = require 'lodash'

connect = require '../lib/connect'

testSettings = {host: 'localhost', port: 27017, db: 'admin', dbOpts: {w: 1, journal: true}}

describe 'connect', ->
  before (done) ->
    # add a user that we can connect to later
    connect testSettings, (err, client) ->
      client.addUser 'Fred', 'Flintstone', (err) ->
        unless err?.code is 11000 # don't care about duplicate
          should.not.exist err
        done()

  it 'should connect anonymous', (done) ->
    connect testSettings, (err, client) ->
      should.not.exist err
      should.exist client
      client.close()
      done()

  it 'should connect with username/password', (done) ->
    credentials = {username: 'Fred', password: 'Flintstone'}
    opts = _.merge {}, testSettings, credentials
    connect opts, (err, client) ->
      should.not.exist err
      should.exist client
      client.close()
      done()
