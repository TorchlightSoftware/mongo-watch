{getType, getTimestamp, objectIDToString, lMissing, rMissing} = require './util'
{Transform, Readable} = require 'stream'
logger = require 'ale'
QueryPayload = require './QueryPayload'
QueryDelta = require './QueryDelta'
formats = require './formats'
{focus} = require 'qi'
_ = require 'lodash'

applyDefaults = (options) ->
  for required in ['client', 'stream', 'collName']
    throw new Error "#{required} required!" unless options[required]?

  options.idSet or= []
  options.format or= 'raw'
  options.select or= {}
  options

makeDeleteEvents = (idSet, client, collName) ->
  return [] unless idSet? and idSet.length > 0
  idSet = idSet.map objectIDToString

  events = for id in idSet
    t: 'p' # type: payload
    ts: getTimestamp()
    op: 'd'
    ns: "#{client.databaseName}.#{collName}"
    _id: id

  return events

class QueryStream extends Transform
  constructor: (options={}) ->
    @options = applyDefaults options
    super {objectMode: true}

    @formatter = formats[@options.format]

    {client, stream, collName, idSet, select} = @options
    payload = new QueryPayload {client, collName, idSet, select}
    delta = new QueryDelta {stream, collName, idSet, select}

    payload.pipe @
    delta.pipe @

  update: ({newIdSet, newSelect}, done) ->
    done ?= ->
    cbGen = focus done

    if newSelect?
      @options.select = newSelect

    {client, stream, collName, select} = @options

    if newIdSet?

      # determine added/removed fields
      unchangedIds = _.intersection newIdSet, @options.idSet
      addedIds = lMissing @options.idSet, newIdSet
      removedIds = rMissing @options.idSet, newIdSet
      @options.idSet = newIdSet
      #logger.magenta {unchangedIds, addedIds, removedIds, newIdSet}

      # get payload, send updates for added fields
      unless _.isEmpty addedIds
        # TODO: translate to simple query and @write
        # call cbGen() and activate when query is done
        payload = new QueryPayload {client, collName, idSet: addedIds, select}
        payload.pipe @

      # send deletes for removed fields
      unless _.isEmpty removedIds
        events = makeDeleteEvents removedIds, client, collName
        @write event for event in events

    else
      unchangedIds = @options.idSet

    if newSelect?
      throw new Error 'not implemented'

    # trigger done if no other callbacks have been generated
    cbGen()()

  _transform: (event, encoding, done) ->
    #logger.grey 'transforming:'.cyan, event

    result = @formatter(event)
    if getType(result) is 'Array'
      @push r for r in result
    else
      @push result

    done()

module.exports = QueryStream
