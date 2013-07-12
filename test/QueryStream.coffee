should = require 'should'
logger = require 'ale'
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

      graham.o.email.should.eql @grahamEmail,

      alice.o.email.should.eql @aliceEmail,

      gUpdate.t.should.eql 'd'
      gUpdate.op.should.eql 'u'
      gUpdate.o.$set.name.should.eql 'Graham',

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

  #it 'should extend selection', (done) ->

    #stream = new QueryStream {client: @watcher.queryClient, stream: @watcher.stream, @collName, idSet: [@aliceId]}

    #stream.once 'data', (event) =>

      #should.exist event._id, 'expected id in first record'
      #event._id.should.eql @aliceId
      #event.t.should.eql 'ep'
      #event.op.should.eql 'i'

      #stream.update {newIdSet: [@aliceId, @grahamId]}, ->

      #stream.once 'data', (event) =>

        #should.exist event?._id, 'expected id in first record'
        #event.t.should.eql 'ep'
        #event.op.should.eql 'i'
        #event._id.should.eql @grahamId

        #done()

  #it 'should contract selection', (done) ->

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
      alice._id.should.eql @grahamId

      done()

  #it 'formatter should split multi-set events', (done) ->
