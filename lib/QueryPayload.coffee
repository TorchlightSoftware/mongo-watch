{Readable} = require 'stream'
logger = require 'ale'

applyDefaults = (options) ->
  for required in ['client', 'collName']
    throw new Error "#{required} required!" unless options[required]?

  options.select or= {}
  options.where or= {}
  options

formatPayload = (records, options) ->
  {client, collection} = options
  #logger.yellow {client}

  oplist = []
  for record in records
    oplist.push {
      operation: 'set'
      path: '.'
      data: record
    }

  return {
    #timestamp: getDate data.ts
    oplist: oplist
    #namespace: data.ns
  }

class QueryPayload extends Readable
  constructor: (options={}) ->
    @options = applyDefaults options
    super {objectMode: true}

    @options.client.collection @options.collName, (err, collection) =>
      return @emit 'error', err if err

      collection.find(@options.where, @options.select).toArray (err, results) =>
        if err
          @emit 'error', err
        else
          @push formatPayload results, @options

  _read: (size) ->
    #logger.blue 'requested read'

module.exports = QueryPayload
