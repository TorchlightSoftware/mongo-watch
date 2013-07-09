{walk, getType, convertObjectID, addTo, listenNTimes} = require '../lib/util'
{ObjectID} = require 'mongodb'
{EventEmitter} = require 'events'

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

  describe 'addTo', ->

    tests = [
        description: 'empty arr'
        arr: []
        item: 1
        expected: [1]
      ,
        description: 'append to arr'
        arr: [1]
        item: 2
        expected: [1, 2]
      ,
        description: 'append multiple'
        arr: [1]
        item: [2, 3]
        expected: [1, 2, 3]
    ]

    for test in tests
      do (test) ->
        {description, arr, item, expected} = test
        it description, ->
          result = addTo arr, item
          result.should.eql expected

  describe 'listenNTimes', ->
    it 'should only call twice', ->
      ee = new EventEmitter

      counter = 1
      listenNTimes ee, 'test', 2, (n) ->
        counter.should.eql n
        counter.should.not.eql 3
        counter++

      ee.emit 'test', 1
      ee.emit 'test', 2
      ee.emit 'test', 3
