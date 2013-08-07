should = require 'should'
{sample} = require '../lib/util'

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

  it 'should ignore {select: true}', (done) ->
    payload = new QueryPayload {client: @watcher.queryClient, @collName, select: true}

    sample payload, 'data', 2, (err, dataset) =>
      [[graham], [alice]] = dataset
      testEvent graham, @grahamEmail
      testEvent alice, @aliceEmail, true
      done()

  it 'should perform idSet filter', (done) ->
    payload = new QueryPayload {client: @watcher.queryClient, @collName, idSet: [@aliceId]}

    payload.once 'data', (event) =>
      testEvent event, @aliceEmail, true
      done()

  it 'should perform select filter', (done) ->
    payload = new QueryPayload {client: @watcher.queryClient, @collName, select: {_id: 1}}

    sample payload, 'data', 2, (err, dataset) =>
      [[graham], [alice]] = dataset

      should.exist graham.o._id
      should.not.exist graham.o.email

      should.exist alice.o._id
      should.not.exist alice.o.email
      done()

boiler 'Query Payload - with no data', (->
  it 'should send a noop end payload', (done) ->
    payload = new QueryPayload {client: @watcher.queryClient, @collName}

    payload.once 'data', (event) =>
      event.should.include {
        t: 'ep'
        op: 'n'
        ns: 'test.users'
      }
      done()

), true # disable data inserts
