#deltas = new QueryDelta {collName, idSet, select}             # stream.Transform (filter with query)
{Transform} = require 'stream'
{walk, objectIDToString, getType} = require './util'
logger = require 'ale'
filterDelta = require './filterDelta'

flag = false

applyDefaults = (options) ->
  for required in ['stream', 'collName']
    throw new Error "#{required} required!" unless options[required]?

  options.select or= {}
  options.idSet or= []
  options

class QueryDelta extends Transform
  constructor: (options={}) ->
    @options = applyDefaults options
    super {objectMode: true}

    @options.stream.pipe @

  _transform: (event, encoding, done) ->
    event = walk event, objectIDToString # fuck ObjectIDs

    # add meta info
    event.t = 'd'
    event._id = event.o2?._id or event.o?._id

    # filter out unwanted fields
    event.o = filterDelta event.o, @options.select
    if event.o

      # filter out unwanted IDs
      if @options.idSet.length > 0
        if event._id in @options.idSet
          @push event
      else
        @push event

    done()

module.exports = QueryDelta
