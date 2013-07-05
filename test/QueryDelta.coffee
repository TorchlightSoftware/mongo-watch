should = require 'should'
logger = require 'ale'

MongoWatch = require '..'
QueryDelta = require '../lib/QueryDelta'
host = 'localhost'
port = 27017
db = 'test'
dbOpts = {w: 1, journal: true}

grahamEmail = 'graham@daventry.com'
aliceEmail = 'alice@daventry.com'

testEvent = (event, email) ->
  should.exist event
  event.should.include {
    t: 'd' # type: delta
    op: 'i'
    ns: 'test.users'
  }
  event.o.email.should.eql email
  should.exist event.o._id

describe 'Query Delta', ->

  collName = 'users'

  before (done) ->
    @watcher = new MongoWatch {host, port, db, dbOpts}
    @watcher.ready =>
      @watcher.queryClient.collection collName, (err, @users) =>
        done()

  afterEach (done) ->
    @users.remove {}, done

  it 'should receive delta event', (done) ->
    delta = new QueryDelta {stream: @watcher.stream, collName}

    @users.insert {email: grahamEmail}, (err, status) =>
      should.not.exist err

    delta.once 'data', (event) ->
      #logger.grey 'event:'.yellow, event
      testEvent event, grahamEmail

      done()

  it 'should filter records', (done) ->
    delta = new QueryDelta {stream: @watcher.stream, collName, where: {email: aliceEmail}}

    @users.insert {email: grahamEmail}, (err, status) =>
      should.not.exist err
      @users.insert {email: aliceEmail}, (err, status) =>
        should.not.exist err

    delta.once 'data', (event) ->
      #logger.grey 'event:'.yellow, event
      testEvent event, aliceEmail

      done()
