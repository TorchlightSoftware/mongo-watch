should = require 'should'
{Server, Db} = require 'mongodb'
{isEqual} = require 'lodash'
{inspect} = require 'util'
logger = (args...) -> console.log args.map((a) -> if (typeof a) is 'string' then a else inspect a, null, 4)...

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

  it 'insert should emit an event', (done) ->
    @watcher = new MongoWatch
    @watcher.watch 'test.users', (event) ->

      if event.op is 'i'
        should.exist event.o?.email
        event.o.email.should.eql 'graham@daventry.com'
        done()

    @users.insert {email: 'graham@daventry.com'}, (err, status) ->
      should.not.exist err

  it 'pretty format should work', (done) ->
    @watcher = new MongoWatch {format: 'pretty'}
    @watcher.watch 'test.users', (event) ->

      if event.operation is 'insert'
        should.exist event.data?.email
        event.data.email.should.eql 'graham@daventry.com'
        done()

    @users.insert {email: 'graham@daventry.com'}, (err, status) ->
      should.not.exist err

  it 'update multiple should emit an event', (done) ->

    # Given I have two users
    @users.insert [{email: 'graham@daventry.com'}, {email: 'valinice@daventry.com'}], (err, status) =>
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
      @users.update {}, data, {multi: true}, (err, status) =>
        should.not.exist err

        # And I update 1 existing document
        @users.update {}, data2, (err, status) ->
          should.not.exist err

  describe 'normal format', ->

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


        @users.update {email: 'graham@daventry.com'}, {firstName: 'Graham'}, (err, status) ->
          should.not.exist err
