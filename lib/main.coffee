{EventEmitter} = require 'events'
formats = require './formats'
connect = require('./connect')

applyDefaults = (options) ->
  options ||= {}
  options.port ||= 27017
  options.host ||= 'localhost'
  options.format ||= 'raw'
  options.onError ||= (error) -> console.log 'Error - MongoWatch:', (error?.stack or error)
  options.onDebug ||= ->
  options

class MongoWatch
  status: 'connecting'
  watching: []

  constructor: (options) ->
    @options = applyDefaults options

    @channel = new EventEmitter
    @channel.on 'error', @options.onError
    @channel.on 'debug', @options.onDebug
    @channel.on 'connected', => @status = 'connected'

    connect @options, (err, @stream) =>
      @channel.emit 'error', err if err
      @channel.emit 'debug', "Emiting 'connected'. Stream exists:", @stream?
      @channel.emit 'connected'

  ready: (done) ->
    isReady = @status is 'connected'
    @channel.emit 'debug', 'Ready:', isReady
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
          @channel.emit 'debug', 'Data changed:', {data: data, watching: collection, relevant: relevant}
          return unless relevant

          channel = if collection then "change:#{collection}" else 'change'
          formatter = formats[@options.format] or formats['raw']
          event = formatter data

          @channel.emit 'debug', 'Emitting event:', {channel: channel, event: event}
          @channel.emit collection, event

        # watch user model
        @channel.emit 'debug', 'Adding emitter for:', {collection: collection}
        @stream.on 'data', watcher

        @watching[collection] = watcher

      @channel.emit 'debug', 'Adding listener on:', {collection: collection}
      @channel.on collection, notify

  stop: (collection) ->
    @channel.emit 'debug', 'Removing listeners for:', collection
    collection ||= 'all'
    @channel.removeAllListeners collection
    @stream.removeListener 'data', @watching[collection]
    delete @watching[collection]

  stopAll: ->
    @stop coll for coll of @watching

module.exports = MongoWatch
