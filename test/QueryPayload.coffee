should = require 'should'
logger = require 'ale'

MongoWatch = require '..'
QueryPayload = require '../lib/QueryPayload'
host = 'localhost'
port = 27017
db = 'test'

grahamEmail = 'graham@daventry.com'
aliceEmail = 'alice@daventry.com'

testEvent = (event, email, end) ->
  should.exist event
  event.should.include {
    t: if end then 'ep' else 'p'
    op: 'i'
    ns: 'test.users'
  }
  event.o.email.should.eql email
  should.exist event.o._id

describe 'Query Payload', ->

  collName = 'users'

  before ->
    @watcher = new MongoWatch {host, port, db}

  beforeEach (done) ->
    @watcher.ready =>
      @watcher.queryClient.collection collName, (err, @users) =>
        @users.insert {email: grahamEmail}, (err, graham) =>
          should.not.exist err
          @grahamId = graham[0]._id
          @users.insert {email: aliceEmail}, (err, alice) =>
            @aliceId = alice[0]._id
            should.not.exist err
            done()

  afterEach (done) ->
    @users.remove {}, done

  it 'should retrieve all users', (done) ->
    payload = new QueryPayload {client: @watcher.queryClient, collName}

    counter = 0
    payload.once 'data', (event) ->
      testEvent event, grahamEmail

      payload.once 'data', (event) ->
        testEvent event, aliceEmail, true

        done()

  it 'should perform where filter', (done) ->
    payload = new QueryPayload {client: @watcher.queryClient, collName, idSet: [@aliceId]}

    payload.once 'data', (event) ->
      testEvent event, aliceEmail, true
      done()

  it 'should perform select filter', (done) ->
    aliceEmail = 'alice@daventry.com'
    payload = new QueryPayload {client: @watcher.queryClient, collName, select: {email: 1, _id: 0}}

    payload.once 'data', (event) ->
      event.o.email.should.eql grahamEmail
      should.not.exist event._id

      payload.once 'data', (event) ->
        event.o.email.should.eql aliceEmail
        should.not.exist event._id
        done()
