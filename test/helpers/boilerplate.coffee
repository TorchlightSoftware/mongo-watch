should = require 'should'
logger = require 'ale'
{sample} = require '../../lib/util'
{focus} = require 'qi'

MongoWatch = require '../..'
host = 'localhost'
port = 27017
db = 'test'
dbOpts = {w: 1, journal: true}

global.boiler = (description, tests) ->
  describe description, ->

    before (done) ->
      @collName = 'users'
      @grahamEmail = 'graham@daventry.com'
      @aliceEmail = 'alice@daventry.com'

      @watcher = new MongoWatch {host, port, db, dbOpts}
      @watcher.ready =>
        @watcher.queryClient.collection @collName, (err, @users) =>
          should.not.exist err
          done()

    beforeEach (done) ->
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


    afterEach (done) ->
      @users.remove {}, (err, numRemoved) =>
      sample @watcher.stream, 'data', 2, done

    tests()
