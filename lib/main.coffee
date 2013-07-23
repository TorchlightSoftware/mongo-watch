{EventEmitter} = require 'events'
relcache = require 'relcache'

formats = require './formats'
connect = require './connect'
getOplogStream = require './getOplogStream'
QueryStream = require './QueryStream'

applyDefaults = (options) ->
  options or= {}
  options.db or= 'local'
  options.dbOpts or= {w: 1}
  options.port or= 27017
  options.host or= 'localhost'
  options.format or= 'raw'
  options

class MongoWatch extends EventEmitter
  status: 'connecting'
  queries: []

  constructor: (options) ->
    @options = applyDefaults options
    super # call EventEmitter constructor with no args

    @on 'connected', => @status = 'connected'
    @debug = @emit.bind(@, 'debug')
    @error = @emit.bind(@, 'error')

    connect @options, (err, @queryClient) =>
      return @error 'Error connecting to database:', err if err

      getOplogStream @options, (err, @stream, @oplogClient) =>
        return @error 'Error establishing oplog watcher:', err if err
        @debug "Connected! Stream exists:", @stream?
        @emit 'connected'

  query: ({collName, idSet, select}, receiver) ->
    return receiver "collName is required." unless collName?
    {format} = @options

    @ready =>
      output = new QueryStream {@stream, client: @queryClient, collName, idSet, format}
      receiver null, output

  ready: (done) ->
    isReady = @status is 'connected'
    @debug 'Ready:', isReady
    if isReady
      return done()

    else
      @once 'connected', done

  shutdown: ->
    @oplogClient?.disconnect()
    @queryClient?.disconnect()
    @stream.end()
    @removeAllListeners()
    for query in @queries
      query.end()
    @queries = []
    @status = 'stopped'

module.exports = MongoWatch
