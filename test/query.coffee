logger = require 'ale'
should = require 'should'
{sample} = require '../lib/util'

boiler 'query', ->

  it 'should receive events for a record', (done) ->

    @watcher.query {@collName, name: 'Alice', format: 'normal'}, (err, stream) =>
      should.not.exist err

      sample stream, 'data', 2, (err, events) =>
        [[graham], [alice]] = events

        graham.t.should.eql 'p'
        graham.op.should.eql 'i'

        alice.t.should.eql 'ep'
        alice.op.should.eql 'i'

        if graham._id is @aliceId
          [graham, alice] = [alice, graham]

        graham.o.email.should.eql @grahamEmail
        alice.o.email.should.eql @aliceEmail

        done()
