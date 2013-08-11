{getType, getTimestamp, objectIDToString, lMissing, rMissing, walk} = require './util'
{Transform, Readable} = require 'stream'
logger = require 'torch'
QueryPayload = require './QueryPayload'
QueryDelta = require './QueryDelta'
formats = require './formats'
{focus} = require 'qi'
_ = require 'lodash'

applyDefaults = (options) ->
  for required in ['client', 'stream', 'collName']
    throw new Error "#{required} required!" unless options[required]?

  options.format or= 'raw'
  options.select or= {}
  options

makeDeleteEvents = (idSet, client, collName) ->
  return [] unless idSet?
  idSet = idSet.map objectIDToString

  events = for id in idSet
    t: 'p' # type: payload
    ts: getTimestamp()
    op: 'd'
    ns: "#{client.databaseName}.#{collName}"
    o: {_id: id}
    _id: id

  return events

makeUnsetEvents = (idSet, selection, client, collName) ->
  return [] unless idSet? and idSet.length > 0
  return [] unless selection? and not _.isEmpty selection
  idSet = idSet.map objectIDToString
  selection = walk selection, objectIDToString

  events = for id in idSet
    t: 'd' # type: delta
    ts: getTimestamp()
    op: 'u'
    ns: "#{client.databaseName}.#{collName}"
    _id: id
    o2: {_id: id}
    o: $unset: selection

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
      addedSelection = lMissing @options.select, newSelect
      removedSelection = rMissing @options.select, newSelect
      @options.select = newSelect

    {client, stream, collName, select} = @options

    # determine added/removed fields
    if newIdSet?
      unchangedIds = _.intersection newIdSet, @options.idSet
      addedIds = lMissing @options.idSet, newIdSet
      removedIds = rMissing @options.idSet, newIdSet
      @options.idSet = newIdSet

    else
      unchangedIds = @options.idSet

    # get payload, send updates for added records
    unless _.isEmpty addedIds
      # TODO: translate to simple query and @write
      # call cbGen() and activate when query is done
      payload = new QueryPayload {client, collName, idSet: addedIds, select}
      payload.pipe @

    # send deletes for removed records
    unless _.isEmpty removedIds
      events = makeDeleteEvents removedIds, client, collName
      @write event for event in events

    # send set fields for newly selected fields
    unless _.isEmpty addedSelection
      payload = new QueryPayload {client, collName, idSet: unchangedIds, select: addedSelection}
      payload.pipe @

    # send unset fields for removed fields
    unless _.isEmpty removedSelection
      events = makeUnsetEvents unchangedIds, removedSelection, client, collName
      @write event for event in events

    # trigger done if no other callbacks have been generated
    cbGen()()

  _transform: (event, encoding, done) ->
    #logger.grey 'transforming:'.cyan, event if getType(event.o) is 'Object' and '$push' in Object.keys(event.o)

    result = @formatter(event)
    if getType(result) is 'Array'
      @push r for r in result
    else
      @push result

    done()

module.exports = QueryStream
