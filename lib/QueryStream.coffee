{getType} = require './util'
{Transform} = require 'stream'
logger = require 'ale'
QueryPayload = require './QueryPayload'
QueryDelta = require './QueryDelta'
formats = require './formats'

applyDefaults = (options) ->
  for required in ['client', 'stream', 'collName']
    throw new Error "#{required} required!" unless options[required]?

  if getType(options.idSet) is 'Array'
    options.idSet = options.idSet.map(stringToObjectID)

  options.format or= 'raw'
  options.select or= {}
  options

class QueryStream extends Transform
  constructor: (options={}) ->
    @options = applyDefaults options
    super {objectMode: true}

    @formatter = formats[@options.format]

    {client, stream, collName, idSet, select} = options
    payload = new QueryPayload {client, collName, idSet, select}
    delta = new QueryDelta {stream, collName, idSet, select}

    payload.pipe @
    delta.pipe @

  _transform: (event, encoding, done) ->
    #logger.grey 'transforming:'.cyan, event
    done null, @formatter event

module.exports = QueryStream
