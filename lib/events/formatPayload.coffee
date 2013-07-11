{getTimestamp, walk, objectIDToString} = require '../util'

module.exports = (records, options) ->
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
