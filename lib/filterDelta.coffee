_ = require 'lodash'
{getType} = require './util'
logger = require 'torch'

module.exports = walk = (event, select) ->

  return null if (select is false) or (select is 0)
  return event unless getType(select) is 'Object'
  return event if _.isEmpty select

  switch getType(event)

    when 'Object'
      copy = {}

      for key, value of event

        # skip select dig for operator key
        if key.match /^\$/
          nextCheck = select
        else
          nextCheck = select[key]

        # keep going if select allows
        if nextCheck
          result = walk value, nextCheck
          copy[key] = result unless result is undefined

      unless _.isEmpty copy
        return copy
      else
        return undefined

    when 'Array'
      copy = for value in event
        walk value, select
      return _.without copy, undefined

    else
      return undefined
