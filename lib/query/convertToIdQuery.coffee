logger = require 'ale'
{getType, addTo} = require '../util'
_ = require 'lodash'
mori = require 'mori'
setToArray = require './setToArray'

# combine a set of results using a given operator
# optional reverse operator for negated sets
combine = (results, op, op2) ->
  op2 ?= op
  _.reduce results, (l, r) ->
    result = {}
    result.in = op l.in, r.in if l.in or r.in
    result.nin = op2 l.nin, r.nin if l.nin or r.nin
    return result

extractIds = (results) ->
  _.map results, '_id'

module.exports = (cache, query) ->
  return {} unless getType(query) is 'Object'


  walk = (op, terms) ->

    idQuery = {}

    if op.match /^\$/

      sub = for k, v of terms
        #logger.blue 'digging:', {k, v}
        walk k, v

      switch op
        when '$and'
          idQuery = combine sub, mori.intersection, mori.union

        when '$or'
          idQuery = combine sub, mori.union, mori.intersection

      logger.cyan {op, combined: idQuery}

    else

      # if we have a comparison operator:
      # http://docs.mongodb.org/manual/reference/operator/#comparison
      if getType(terms) is 'Object'

        for k, v of terms
          if k.match /^\$/
            comparitor = k.substring 1

            # cache supports all comparison operators listed at url above
            results = cache.query op, comparitor, v
            logger.yellow "#{op} $#{comparitor} #{v}:", results
            idQuery.in = mori.set extractIds results

          else
            # maybe we're comparing a real object value?

      # otherwise it's a regular equality query
      else
        results = cache.get op, terms
        idQuery.in = mori.set extractIds results

      logger.magenta {original: idQuery}

    return idQuery

  # default behavior for the root is an '$and' so evaluate this explicitly
  result = walk '$and', query
  logger.magenta {result}

  return setToArray result
