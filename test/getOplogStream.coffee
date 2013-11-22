logger = require 'torch'
should = require 'should'
_ = require 'lodash'

connect = require '../lib/connect'
getOplogStream = require '../lib/getOplogStream'

describe 'getOplogStream', ->
  #before (done) ->
    ## add a user that we can connect to later
    #opts = _.merge {}, testSettings, {db: 'local'}
    #connect testSettings, (err, client) ->
      #client.addUser 'Fred', 'Flintstone', (err) ->
        #should.not.exist err
        #done()

  it 'should connect anonymous', (done) ->
    getOplogStream testSettings, (err, client) ->
      should.not.exist err
      should.exist client
      done()

  #it 'should connect with username/password', (done) ->
    #credentials = {username: 'Fred', password: 'Flintstone'}
    #opts = _.merge {}, testSettings, credentials
    #getOplogStream opts, (err, client) ->
      #should.not.exist err
      #should.exist client
      #done()
