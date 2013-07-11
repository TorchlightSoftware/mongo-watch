{getTimestamp, walk, objectIDToString, stringToObjectID, getType} = require './util'
{Readable} = require 'stream'
logger = require 'ale'

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

formatPayload = (records, options) ->
  return [] unless records? and records.length > 0

  {client, collName} = options
  #logger.yellow {client}

  events = for record in records
    t: 'p' # type: payload
    ts: getTimestamp()
    op: 'i'
    ns: "#{client.databaseName}.#{collName}"
    _id: record._id
    o: record

  events = walk events, objectIDToString
  events[events.length - 1].t = 'ep' # end payload
  return events

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
