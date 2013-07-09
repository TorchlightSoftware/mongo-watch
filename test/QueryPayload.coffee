should = require 'should'

QueryPayload = require '../lib/QueryPayload'

testEvent = (event, email, end) ->
  should.exist event, 'expected event to exist'
  event.should.include {
    t: if end then 'ep' else 'p'
    op: 'i'
    ns: 'test.users'
  }
  event.o.email.should.eql email
  should.exist event.o._id

boiler 'Query Payload', ->

  it 'should retrieve all users', (done) ->
    payload = new QueryPayload {client: @watcher.queryClient, @collName}

    counter = 0
    payload.once 'data', (event) =>
      testEvent event, @grahamEmail

      payload.once 'data', (event) =>
        testEvent event, @aliceEmail, true

        done()

  it 'should perform idSet filter', (done) ->
    payload = new QueryPayload {client: @watcher.queryClient, @collName, idSet: [@aliceId]}

    payload.once 'data', (event) =>
      testEvent event, @aliceEmail, true
      done()

  it 'should perform select filter', (done) ->
    aliceEmail = 'alice@daventry.com'
    payload = new QueryPayload {client: @watcher.queryClient, @collName, select: {email: 1, _id: 0}}

    payload.once 'data', (event) =>
      event.o.email.should.eql @grahamEmail
      should.not.exist event._id, 'expected no event._id'

      payload.once 'data', (event) =>
        event.o.email.should.eql @aliceEmail
        should.not.exist event._id, 'expected no event._id'
        done()
