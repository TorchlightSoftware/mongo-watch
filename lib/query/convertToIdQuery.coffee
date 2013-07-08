logger = require 'ale'
{getType, addTo} = require '../util'
_ = require 'lodash'
mori = require 'mori'
setToArray = require './setToArray'

# combine a set of results using a given operator
# optional reverse operator for negated sets
#combine = (results, op, op2) ->
  #op2 ?= op
  #_.reduce results, (l, r) ->
    #result = {}
    #result.in = op l.in, r.in if l.in or r.in
    #result.nin = op2 l.nin, r.nin if l.nin or r.nin
    #return result

combine = (results, op) ->
  # only pass first two arguments, otherwise mori tries to interpret
  # index as a set
  _.reduce results, (l, r) ->
    op l, r

extractIds = (results) ->
  _.map results, '_id'

module.exports = (cache, query) ->
  return {} unless getType(query) is 'Object'


  walk = (op, terms) ->

    idSet = null

    if op.match /^\$/

      sub = for k, v of terms
        #logger.blue 'digging:', {k, v}
        walk k, v

      switch op
        when '$and'
          idSet = combine sub, mori.intersection

        when '$or'
          idSet = combine sub, mori.union

      #logger.cyan {op, combined: idSet}

    else

      # if we have a comparison operator:
      # http://docs.mongodb.org/manual/reference/operator/#comparison
      if getType(terms) is 'Object'

        sub = for k, v of terms
          if k.match /^\$/
            comparitor = k.substring 1

            # cache supports all comparison operators listed at url above
            results = cache.query op, comparitor, v
            mori.set extractIds results

          else
            # maybe we're comparing a real object value?
            undefined

        sub = _.compact sub # discard those undefined's!
        idSet = combine sub, mori.intersection

      # otherwise it's a regular equality query
      else
        results = cache.get op, terms
        idSet = mori.set extractIds results

      #logger.magenta {original: idSet}

    return idSet

  # default behavior for the root is an '$and' so evaluate this explicitly
  result = walk '$and', query
  #logger.magenta {result}

  return mori.into_array result
