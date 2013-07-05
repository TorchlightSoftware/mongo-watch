#deltas = new QueryDelta {collName, where, select}             # stream.Transform (filter with query)
{Transform} = require 'stream'
logger = require 'ale'

applyDefaults = (options) ->
  for required in ['stream', 'collName']
    throw new Error "#{required} required!" unless options[required]?

  options.select or= {}
  options.where or= {}
  options

class QueryDelta extends Transform
  constructor: (options={}) ->
    @options = applyDefaults options
    super {objectMode: true}

    @options.stream.pipe @

  _transform: (event, encoding, done) ->
    #logger.grey 'transform event:'.magenta, event

    event.t = 'd'
    if Object.keys(@options.where).length > 0
      #logger.blue {event, where: @options.where}
      if event.o.email is @options.where.email
        @push event
    else
      @push event

    done()

module.exports = QueryDelta
