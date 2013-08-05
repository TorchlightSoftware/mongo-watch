should = require 'should'
logger = require 'torch'
QueryStream = require '../lib/QueryStream'
{sample} = require '../lib/util'

boiler 'Query Stream', ->

  it 'should combine the payload and delta', (done) ->

    stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName}

    sample stream, 'data', 3, (err, dataset) =>
      should.not.exist err
      [[graham], [alice], [gUpdate]] = dataset

      graham.t.should.eql 'p'
      graham.op.should.eql 'i'

      alice.t.should.eql 'ep'
      alice.op.should.eql 'i'

      if graham._id is @aliceId
        [graham, alice] = [alice, graham]

      graham.o.email.should.eql @grahamEmail

      alice.o.email.should.eql @aliceEmail

      gUpdate.t.should.eql 'd'
      gUpdate.op.should.eql 'u'
      gUpdate.o.$set.name.should.eql 'Graham'

      done()

    @users.update {email: @grahamEmail}, {$set: {name: 'Graham'}}, (err, status) =>
      should.not.exist err

  it 'should filter by id', (done) ->

    stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName, idSet: [@aliceId]}

    stream.once 'data', (event) =>

      should.exist event?._id, 'expected id in event'
      event.t.should.eql 'ep'
      event._id.should.eql @aliceId

      done()

  it 'should extend idSet', (done) ->

    stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName, idSet: [@aliceId]}

    stream.once 'data', (event) =>

      should.exist event._id, 'expected id in first record'
      event._id.should.eql @aliceId
      event.t.should.eql 'ep'
      event.op.should.eql 'i'

      stream.update {newIdSet: [@aliceId, @grahamId]}, ->

      stream.once 'data', (event) =>

        should.exist event?._id, 'expected id in first record'
        event.t.should.eql 'ep'
        event.op.should.eql 'i'
        event._id.should.eql @grahamId

        done()

  it 'should contract idSet', (done) ->
    stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName, idSet: [@aliceId]}

    stream.once 'data', (event) =>

      should.exist event._id, 'expected id in first record'
      event._id.should.eql @aliceId

      stream.update {newIdSet: []}, ->

      stream.once 'data', (event) =>

        should.exist event?._id, 'expected id in first record'
        event.t.should.eql 'p'
        event.op.should.eql 'd'
        event._id.should.eql @aliceId

        done()

  it 'should perform selection', (done) ->
    stream = new QueryStream {
      client: @watcher.queryClient
      stream: @watcher.stream
      @collName
      select: {name: true}
    }

    sample stream, 'data', 3, (err, dataset) =>
      should.not.exist err
      [[insert], _, [update]] = dataset

      update.should.include {
        t: 'd'
        op: 'u'
        ns: 'test.users'
        o2: {_id: @grahamId}
        _id: @grahamId
      }
      should.exist update?.o?.$set, 'expected $set operation'
      update.o.$set.should.include {name: 'Graham'}
      update.o.$set.should.not.include {loginCount: 5}
      done()

    @users.update {email: @grahamEmail}, {$set: {name: 'Graham', loginCount: 5}}, (err, status) =>
      should.not.exist err

  it 'should extend selection', (done) ->

    stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName, select: {_id: true}}

    sample stream, 'data', 2, (err, dataset) =>
      [[first]] = dataset
      keys = Object.keys(first.o)
      keys.should.include '_id'
      keys.should.not.include 'email'

      stream.update {newSelect: {_id: true, email: true}}, ->

      sample stream, 'data', 2, (err, dataset) =>
        [[first]] = dataset
        keys = Object.keys(first.o)
        keys.should.include '_id'
        keys.should.include 'email'

        done()

  it 'should contract selection', (done) ->

    stream = new QueryStream {
      client: @watcher.queryClient
      stream: @watcher.stream
      @collName
      idSet: [@aliceId, @grahamId]
      select: {_id: true, email: true}
    }

    sample stream, 'data', 2, (err, dataset) =>
      [[first]] = dataset
      should.exist first?.o?.email, 'expected email in initial'
      should.exist first?.o?._id, 'expected _id in initial'

      stream.update {newSelect: {_id: true}}, ->

      sample stream, 'data', 2, (err, dataset) =>
        [[first]] = dataset
        should.exist first?.o?.$unset?.email, 'expected {$unset: email}'

        done()

  # This doesn't work now because we have to send update events for all records...
  # But we never recorded which records are present.
  # Is it important?  If the consumer is caching, it should be updating us with a full list of IDs.
  #
  #it 'should contract selection with no idSet', (done) ->

  it 'should apply a format', (done) ->

    stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName, format: 'normal'}

    sample stream, 'data', 2, (err, dataset) =>
      should.not.exist err

      [[graham], [alice]] = dataset
      if graham._id is @aliceId
        [graham, alice] = [alice, graham]

      graham.should.include {
        operation: 'set'
        path: '.'
        data: {email: @grahamEmail}
        namespace: 'test.users'
      }
      graham._id.should.eql @grahamId

      alice.should.include {
        operation: 'set'
        path: '.'
        data: {email: @aliceEmail}
        namespace: 'test.users'
      }
      alice._id.should.eql @aliceId

      done()

  it 'formatter should split multi-set events', (done) ->

    stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName, format: 'normal'}

    sample stream, 'data', 4, (err, dataset) =>
      should.not.exist err
      [_, _, [setEvent], [pushEvent]] = dataset
      if setEvent.operation is 'push'
        [pushEvent, setEvent] = [setEvent, pushEvent]

      setEvent.should.include {
        operation: 'set'
        path: 'name'
        data: 'Graham'
        namespace: 'test.users'
      }

      pushEvent.should.include {
        operation: 'push'
        path: 'friends'
        data: 56
        namespace: 'test.users'
      }

      done()

    # MONGO BUG: This doesn't work... the $inc command doesn't make it through to the oplog
    #@users.update {email: @grahamEmail}, {$set: {name: 'Graham'}, $inc: {loginCount: 1}}, (err, status) =>

    @users.update {email: @grahamEmail}, {$set: {name: 'Graham'}, $push: {friends: 56}}, (err, status) =>
      should.not.exist err

  #it 'should stop processing', (done) ->
    #stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName, format: 'normal'}
    #stream.end()

    #@watcher.stream.on 'data', (event) ->
      # look for the event
      # process.nextTick ->
      #   should not have fired QueryStream

boiler 'Query Stream', (->
  it 'format an empty payload', (done) ->

    stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName, format: 'normal'}

    stream.once 'data', (event) ->
      event.should.include {
        operation: 'noop',
        origin: 'end payload',
        namespace: 'test.users'
      }
      done()
), true
