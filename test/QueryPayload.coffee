should = require 'should'
logger = require 'ale'

MongoWatch = require '..'
QueryPayload = require '../lib/QueryPayload'
host = 'localhost'
port = 27017

describe 'Query Payload', ->

  collName = 'users'

  before ->
    @watcher = new MongoWatch {host, port}

  beforeEach (done) ->
    @watcher.on 'error', done
    @watcher.ready =>
      @watcher.queryClient.collection collName, (err, @users) =>
        @users.insert {email: 'graham@daventry.com'}, (err, status) =>
          should.not.exist err
          @users.insert {email: 'alice@daventry.com'}, (err, status) =>
            should.not.exist err
            done()

  afterEach (done) ->
    @users.remove {}, done

  it 'should retrieve all users', (done) ->
    payload = new QueryPayload {client: @watcher.queryClient, collName}

    payload.on 'data', (event) ->
      should.exist event?.oplist
      event.oplist.length.should.eql 2
      done()

  it 'should perform where filter', (done) ->
    aliceEmail = 'alice@daventry.com'
    payload = new QueryPayload {client: @watcher.queryClient, collName, where: {email: aliceEmail}}

    payload.on 'data', (event) ->
      should.exist event?.oplist
      event.oplist.length.should.eql 1
      event.oplist[0].data.email.should.eql aliceEmail
      done()

  it 'should perform select filter', (done) ->
    aliceEmail = 'alice@daventry.com'
    payload = new QueryPayload {client: @watcher.queryClient, collName, select: {email: 1, _id: 0}}

    payload.on 'data', (event) ->
      should.exist event?.oplist
      event.oplist.length.should.eql 2
      for op in event.oplist
        keys = Object.keys(op.data)
        keys.should.include 'email'
        keys.should.not.include '_id'
      done()
