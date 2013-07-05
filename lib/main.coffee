{EventEmitter} = require 'events'
formats = require './formats'
connect = require './connect'
getOplogStream = require './getOplogStream'

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

  query: ({collName, where, select}, receiver) ->
    #return receiver "Collection is required." unless collection?
    #where or= {}
    #select or= {}

    #@ready =>

      #formatter = formats[@options.format]

      #payload = new QueryPayload {@queryClient, collName, where, select}  # stream.Readable (emit payload as 'set' event)
      #deltas = new QueryDelta {@stream, collName, where, select}          # stream.Transform (filter with query)
      #output = new WatchStream {formatter}                                # stream.Transform (apply selected formatter)

      #payload.pipe(output)
      #@stream.pipe(deltas)
      #deltas.pipe(output)

      #receiver null, output

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
