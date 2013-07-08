{getType} = require '../util'
mori = require 'mori'

module.exports = (query) ->
  return [] unless getType(query) is 'Object'

  keys = mori.set []

  walk = (obj) ->
    for k, v of obj
      if k.match /^\$/ # recurse if it's a mongo op
        walk v
      else
        keys = mori.conj keys, k

  walk query
  return mori.into_array keys
