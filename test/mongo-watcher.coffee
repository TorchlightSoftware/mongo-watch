should = require 'should'
{Server, Db} = require 'mongodb'

MongoWatch = require '../'

describe 'Mongo Watch', ->

  before (done) ->
    client = new Db 'test', new Server('localhost', 27017), {w: 1}

    client.open (err) =>
      return done err if err

      client.collection 'users', (err, @users) =>
        done err

  afterEach ->
    @watcher.stopAll() if @watcher
    @users.remove {}, ->

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
