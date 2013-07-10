should = require 'should'
Relcache = require 'relcache'
logger = require 'ale'
importKeys = require '../lib/cache/importKeys'

boiler 'importKeys', ->

  it 'should not return until the cache contains all the keys', (done) ->
    logger 'importing keys'
    importKeys @relcache, @collName, ['email'], (err) =>
      logger 'done importing'
      gRel = @relcache.get 'email', @grahamEmail
      should.exist gRel[0]._id
      gRel[0]._id.should.eql @grahamId

      aRel = @relcache.get 'email', @aliceEmail
      should.exist aRel[0]._id
      aRel[0]._id.should.eql @aliceId
      done()
