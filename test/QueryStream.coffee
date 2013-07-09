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
      graham.o.email.should.eql @grahamEmail,

      alice.t.should.eql 'ep'
      alice.op.should.eql 'i'
      alice.o.email.should.eql @aliceEmail,

      gUpdate.t.should.eql 'd'
      gUpdate.op.should.eql 'u'
      gUpdate.o.$set.name.should.eql 'Graham',

      done()

    @users.update {email: @grahamEmail}, {$set: {name: 'Graham'}}, (err, status) =>
      should.not.exist err
