should = require 'should'
logger = require 'ale'

QueryDelta = require '../lib/QueryDelta'

testEvent = (event, name) ->
  should.exist event
  event.should.include {
    t: 'd' # type: delta
    op: 'u'
    ns: 'test.users'
  }
  should.exist event?.o?.$set?.name, 'expected name'
  event.o.$set.name.should.eql name
  should.exist event._id, 'expected _id'

boiler 'Query Delta', ->

  it 'should receive delta event', (done) ->
    delta = new QueryDelta {stream: @watcher.stream, @collName}

    @users.update {email: @grahamEmail}, {$set: {name: 'Graham'}}, (err, status) =>
      should.not.exist err

    delta.once 'data', (event) =>
      testEvent event, 'Graham'

      done()

  it 'should filter records', (done) ->
    delta = new QueryDelta {stream: @watcher.stream, @collName, idSet: [@aliceId]}

    delta.once 'data', (event) =>
      testEvent event, 'Alice'
      done()

    @users.update {email: @grahamEmail}, {$set: {name: 'Graham'}}, (err, status) =>
      should.not.exist err
      @users.update {email: @aliceEmail}, {$set: {name: 'Alice'}}, (err, status) =>
        should.not.exist err
