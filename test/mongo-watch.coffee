should = require 'should'
{Server, Db} = require 'mongodb'
{isEqual} = require 'lodash'
{inspect} = require 'util'

MongoWatch = require '../'

describe 'Mongo Watch', ->

  before (done) ->
    client = new Db 'test', new Server('localhost', 27017), {w: 1}

    client.open (err) =>
      return done err if err

      client.collection 'users', (err, @users) =>
        done err

  afterEach (done) ->
    @watcher.stopAll() if @watcher
    delete @watcher
    @users.remove {}, done

  it 'with no activity should not receive events', (done) ->
    @watcher = new MongoWatch #{onDebug: logger.yellow}
    @watcher.watch 'test.users', (event) ->
      throw new Error "Expected no events. Got:\n#{inspect event, null, null}"
    setTimeout done, 20

  it 'insert should emit an event', (done) ->
    @watcher = new MongoWatch #{onDebug: logger.yellow}
    @watcher.watch 'test.users', (event) ->
      #logger.yellow event

      if event.op is 'i'
        should.exist event.o?.email
        event.o.email.should.eql 'billy@daventry.com'
        done()

    @watcher.ready =>
      @users.insert {email: 'billy@daventry.com'}, (err, status) ->
        should.not.exist err

  it 'pretty format should work', (done) ->
    @watcher = new MongoWatch {format: 'pretty', convertObjectIDs: true}
    @watcher.watch 'test.users', (event) ->
      event.operation.should.eql 'insert'
      should.exist event.data?.email
      event.data._id.constructor.name.should.eql 'String'
      event.data.email.should.eql 'graham@daventry.com'
      done()

    @watcher.ready =>
      @users.insert {email: 'graham@daventry.com'}, (err, status) ->
        should.not.exist err

  it 'pretty format should optionally convert ObjectIDs', (done) ->
    @watcher = new MongoWatch {format: 'pretty', convertObjectIDs: false}
    @watcher.watch 'test.users', (event) ->
      event.data._id.constructor.name.should.eql 'ObjectID'
      done()

    @watcher.ready =>
      @users.insert {email: 'graham@daventry.com'}, (err, status) ->
        should.not.exist err

  it 'update multiple should emit an event', (done) ->

    # Given I have two users
    @users.insert [{email: 'richard@daventry.com'}, {email: 'valinice@daventry.com'}], (err, status) =>
      should.not.exist err

      # And I'm watching the users collection
      counter = 0
      @watcher = new MongoWatch {format: 'pretty'}
      @watcher.watch 'test.users', (event) ->

        # I should get three update events
        if event.operation is 'update'
          counter++
          if counter is 3
            done()

      data =
        '$set':
          firstName: 'Trickster'
        '$pushAll':
          'stuff': [
              text: 'trick you'
            ,
              text: 'try you'
          ]
        '$unset':
          lastName: true

      data2 =
        '$pull':
          'stuff':
            timestamp: '$lte': new Date()
        '$set':
          'foo.bar.baz': 'herro'

      # When I update 2 existing documents
      @watcher.ready =>
        @users.update {}, data, {multi: true}, (err, status) =>
          should.not.exist err

          # And I update 1 existing document
          @users.update {}, data2, (err, status) ->
            should.not.exist err

  expectOp = (event, expected, done) ->
    for op in event.oplist
      (typeof op.id).should.eql 'string', 'Expected id to be a string.'
      delete op.id
      if isEqual op, expected
        done()

  it 'should process insert', (done) ->
    @watcher = new MongoWatch {format: 'normal'}
    @watcher.watch 'test.users', (event) ->
      should.exist event.timestamp
      expected = {
        operation: 'set'
        path: '.'
        data: {email: 'graham@daventry.com'}
      }
      expectOp event, expected, done

    @watcher.ready =>
      @users.insert {email: 'graham@daventry.com'}, (err, status) ->
        should.not.exist err

  it 'should process simple update', (done) ->
    @users.insert {email: 'graham@daventry.com'}, (err, status) =>
      should.not.exist err

      @watcher = new MongoWatch {format: 'normal'}
      @watcher.watch 'test.users', (event) ->
        should.exist event.timestamp, 'expected timestamp'
        should.exist event.oplist, 'expected oplist'
        expected = {
          operation: 'set'
          path: '.'
          data: {firstName: 'Graham'}
        }
        expectOp event, expected, done

      @watcher.ready =>
        @users.update {email: 'graham@daventry.com'}, {firstName: 'Graham'}, (err, status) ->
          should.not.exist err
