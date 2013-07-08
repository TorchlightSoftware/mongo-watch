logger = require 'ale'
{getType} = require '../util'
mori = require 'mori'

module.exports = (query) ->

  walk = (node) ->

    nodeType = getType(node)
    #logger.blue {nodeType}
    switch nodeType
      when 'Object'
        for k, v of node
          node[k] = walk v
        return node

      when 'Hi' # uh... thanks ClojureScript?
        return mori.into_array node

      else # yeah... just do it anyway
        return mori.into_array node

  return walk query
