{EventEmitter} = require 'events'
formats = require './formats'
getOplogStream = require './getOplogStream'
{walk, convertObjectID} = require './util'

applyDefaults = (options) ->
  options or= {}
  options.port or= 27017
  options.host or= 'localhost'
  options.authdb or= 'admin'
  options.replicaSet or= null
  options.dbOpts or= {w: 1}
  options.format or= 'raw'
  options.useMasterOplog or= false
  options.convertObjectIDs ?= true
  options.onError or= (error) -> console.log 'Error - MongoWatch:', (error?.stack or error)
  options.onDebug or= ->
    #options.username or= null
    #options.password or= null
  return options

class MongoWatch
  status: 'connecting'
  watching: []

  constructor: (options) ->
    @options = applyDefaults options

    @channel = new EventEmitter
    @channel.on 'error', @options.onError
    @channel.on 'connected', => @status = 'connected'
    @debug = @options.onDebug

    getOplogStream @options, (err, @stream, @oplogClient) =>
      @channel.emit 'error', err if err
      @debug "Emiting 'connected'. Stream exists:", @stream?
      @channel.emit 'connected'

  ready: (done) ->
    isReady = @status is 'connected'
    @debug 'Ready:', isReady
    if isReady
      return done()

    else
      @channel.once 'connected', done

  watch: (collection, notify) ->
    collection ||= 'all'
    notify ||= console.log

    @ready =>
      unless @watching[collection]?

        watcher = (data) =>
          relevant = (collection is 'all') or (data.ns is collection)
          @debug 'Data changed:', {data: data, watching: collection, relevant: relevant}
          return unless relevant

          channel = if collection then "change:#{collection}" else 'change'
          formatter = formats[@options.format] or formats['raw']
          event = formatter data

          # convert ObjectIDs to strings
          if @options.convertObjectIDs is true
            event = walk event, convertObjectID

          @debug 'Emitting event:', {channel: channel, event: event}
          @channel.emit collection, event

        # watch user model
        @debug 'Adding emitter for:', {collection: collection}
        @stream.on 'data', watcher

        @watching[collection] = watcher

      @debug 'Adding listener on:', {collection: collection}
      @channel.on collection, notify

  stop: (collection) ->
    @debug 'Removing listeners for:', collection
    collection ||= 'all'
    @channel.removeAllListeners collection
    @stream.removeListener 'data', @watching[collection]
    delete @watching[collection]

  stopAll: ->
    @stop coll for coll of @watching

module.exports = MongoWatch
