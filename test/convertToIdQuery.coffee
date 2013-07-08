should = require 'should'
convertToIdQuery = require '../lib/query/convertToIdQuery'
relcache = require 'relcache'
logger = require 'ale'

describe 'convertToIdQuery', ->

  # we assume that all indexed fields are densely populated:
  # they should have a definition even if the value is null or undefined
  relcache.set 'name', 'Alice',   {_id: 2}
  relcache.set 'name', 'Ken',     {_id: 5}
  relcache.set 'name', 'Bob',     {_id: 7}
  relcache.set 'name', 'Jane',    {_id: 9}
  relcache.set 'name', 'Max',     {_id: 13}
  relcache.set 'name', 'Shannon', {_id: 19}

  relcache.set 'country', 'USA',    {_id: 2}
  relcache.set 'country', 'Mexico', {_id: 5}
  relcache.set 'country', 'Canada', {_id: 7}
  relcache.set 'country', 'Canada', {_id: 9}
  relcache.set 'country', 'USA',    {_id: 13}
  relcache.set 'country', 'USA',    {_id: 19}

  relcache.set 'loginCount', 0,  {_id: 2}
  relcache.set 'loginCount', 9,  {_id: 5}
  relcache.set 'loginCount', 10, {_id: 7}
  relcache.set 'loginCount', 7,  {_id: 9}
  relcache.set 'loginCount', 16, {_id: 13}
  relcache.set 'loginCount', 12, {_id: 19}

  tests = [
      description: 'simple keys'
      input: {name: 'Ken'}
      output: [5]
    ,
      description: 'negation'
      input: {name: {$ne: 'Ken'}}
      output: [2, 7, 9, 13, 19]
        #nin: [5]
    ,
      description: 'nested keys'
      input: {$or: {name: 'Ken', country: 'Canada'}}
      output: [7, 9, 5]
    ,
      description: 'comparison operator'
      input: {loginCount: {$gte: 10}}
      output: [7, 19, 13]
    ,
      description: "'and' reduced to empty set"
      input: {$and: {name: 'Ken', loginCount: {$gte: 10}}}
      #output: and: [{in: [5]}, {in: 7, 19, 13}]
      #output: and: in: []
      output: []
    ,
      description: "root 'and' behavior"
      input: {$and: {name: 'Ken', loginCount: {$gte: 9}}}
      output: [5]
    ,
      description: 'remove exception'
      input: {$and: {loginCount: {$gte: 9}, name: {$ne: 'Ken'}}}
      output: [7, 19, 13]
  ]

  for test in tests
    do (test) ->
      {description, input, output} = test
      it description, ->
        result = convertToIdQuery relcache, input
        result.should.eql output
