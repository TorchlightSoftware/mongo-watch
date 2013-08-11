{stringToObjectID, getTimestamp} = require './util'
{Readable} = require 'stream'
logger = require 'torch'
formatPayload = require './events/formatPayload'

applyDefaults = (options) ->
  for required in ['client', 'collName']
    throw new Error "#{required} required!" unless options[required]?

  options.select ?= {}
  options.select = {} if options.select is true
  options

idSetToQuery = (idSet) ->
  if idSet?
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

          if results.length > 0
            for event in formatPayload results, @options
              @push event

          # we got no data, so send a noop/end payload to tell the listener we are done
          else
            @push {
              t: 'ep'
              op: 'n'
              ns: 'test.users'
              ts: getTimestamp()
            }

  _read: (size) ->
    #logger.blue 'requested read'

module.exports = QueryPayload
