should = require 'should'
logger = require 'torch'
{sample} = require '../../lib/util'
{focus} = require 'qi'

require('../../lib/patchEventEmitter')() # suppress warnings

MongoWatch = require '../..'
host = 'localhost'
port = 27017
db = 'test'
dbOpts = {w: 1, journal: true}

global.testSettings = {host, port, db, dbOpts}

global.boiler = (description, tests, disableData) ->
  describe description, ->

    before (done) ->
      @collName = 'users'
      @grahamEmail = 'graham@daventry.com'
      @aliceEmail = 'alice@daventry.com'

      @watcher = new MongoWatch {host, port, db, dbOpts}
      @watcher.ready =>
        @watcher.queryClient.collection @collName, (err, @users) =>
          should.not.exist err
          @watcher.queryClient.collection 'stuffs', (err, @stuffs) =>
            should.not.exist err
            done()

    beforeEach (done) ->
      return done() if disableData

      cbGen = focus (err, records) =>
        should.not.exist err
        {g: [graham], a: [alice]} = records
        @aliceId = alice._id.toString()
        @grahamId = graham._id.toString()
        done()

      @users.insert {email: @grahamEmail}, cbGen('g')
      @users.insert {email: @aliceEmail}, cbGen('a')

      # wait for oplog events to fire so they don't interfere with tests
      sample @watcher.stream, 'data', 2, cbGen()

    # an attempt to make sure deletion events don't affect the next test
    afterEach (done) ->
      expecting = null
      got = 0

      check = =>
        if expecting? and got >= expecting
          expecting = null
          @watcher.stream.removeListener 'data', watch
          done()

      watch = (event) ->
        if event.op is 'd'
          got++
          check()

      @watcher.stream.on 'data', watch

      @stuffs.remove {}, =>
        @users.remove {}, (err, numRemoved) =>
          expecting = numRemoved
          check()

    tests()
