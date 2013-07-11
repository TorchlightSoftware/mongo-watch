{stringToObjectID} = require './util'
{Readable} = require 'stream'
logger = require 'ale'
formatPayload = require './events/formatPayload'

applyDefaults = (options) ->
  for required in ['client', 'collName']
    throw new Error "#{required} required!" unless options[required]?

  options.idSet ?= []
  options.select ?= {}
  options

idSetToQuery = (idSet) ->
  if idSet? and idSet.length > 0
    {_id: {$in: idSet.map(stringToObjectID)}}
  else
    {}

class QueryPayload extends Readable
  constructor: (options={}) ->
    @options = applyDefaults options
    super {objectMode: true}

    #TODO: idSet needs to be converted to ObjectIDs!
    @query = idSetToQuery @options.idSet

    @options.client.collection @options.collName, (err, collection) =>
      return @emit 'error', err if err

      collection.find(@query, @options.select).toArray (err, results) =>
        if err
          @emit 'error', err
        else
          for event in formatPayload results, @options
            @push event

  _read: (size) ->
    #logger.blue 'requested read'

module.exports = QueryPayload
