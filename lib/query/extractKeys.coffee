{getType, addUnique} = require '../util'
logger = require 'ale'

module.exports = (query) ->
  return [] unless getType(query) is 'Object'

  keys = []

  walk = (obj) ->
    for k, v of obj
      if k.match /^\$/ # recurse if it's a mongo op
        walk v
      else
        addUnique keys, k

  walk query
  return keys
