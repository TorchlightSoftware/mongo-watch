should = require 'should'
extractKeys = require '../lib/query/extractKeys'

describe 'extractKeys', ->
  tests = [
      description: 'simple keys'
      input: {name: 'Ken'}
      output: ['name']
    ,
      description: 'nested keys'
      input: {$or: {name: 'Ken', country: 'Canada'}}
      output: ['name', 'country']
    ,
      description: 'comparison operator'
      input: {loginCount: {$gte: 10}}
      output: ['loginCount']
    ,
      description: 'mixed'
      input: {name: 'Ken', loginCount: {$gte: 10}}
      output: ['name', 'loginCount']
  ]

  for test in tests
    do (test) ->
      {description, input, output} = test
      it description, ->
        result = extractKeys input
        result.should.eql output
