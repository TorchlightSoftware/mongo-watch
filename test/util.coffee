{walk, getType, convertObjectID} = require '../lib/util'
{ObjectID} = require 'mongodb'

describe 'util', ->

  describe 'walk', ->

    identity = (data) -> data
    objID = new ObjectID

    tests = [
        description: 'identity function should process array'
        input: [1, 2, 3, 4]
        expected: [1, 2, 3, 4]
        fn: identity
      ,
        description: 'identity function should process object'
        input: {a: 1, b: 2}
        expected: {a: 1, b: 2}
        fn: identity
      ,
        description: 'identity function should process complex structure'
        input: {a: 1, b: [1, 2, {foo: 3}]}
        expected: {a: 1, b: [1, 2, {foo: 3}]}
        fn: identity
      ,
        description: 'double should work with complex structure'
        input: {a: 1, b: [1, 2, {foo: 3}]}
        expected: {a: 2, b: [2, 4, {foo: 6}]}
        fn: (x) -> x * 2
      ,
        description: 'should replace ObjectID with string'
        input: {a: 1, b: [1, 2, {_id: objID}]}
        expected: {a: 1, b: [1, 2, {_id: objID.toString()}]}
        fn: convertObjectID
    ]

    for test in tests
      do (test) ->
        {description, input, expected, fn} = test
        it description, ->
          result = walk input, fn
          result.should.eql expected

  describe 'getType', ->

    tests = [
        description: 'empty object'
        input: {}
        expected: 'Object'
      ,
        description: 'empty array'
        input: []
        expected: 'Array'
      ,
        description: 'error'
        input: new Error
        expected: 'Error'
      ,
        description: 'string'
        input: 'hi'
        expected: 'String'
      ,
        description: 'undefined'
        input: undefined
        expected: 'Undefined'
      ,
        description: 'null'
        input: null
        expected: 'Null'
      ,
        description: 'ObjectID'
        input: new ObjectID()
        expected: 'ObjectID'
    ]

    for test in tests
      do (test) ->
        {description, input, expected} = test
        it description, ->
          result = getType input
          result.should.eql expected
