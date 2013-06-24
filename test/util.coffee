{walk} = require '../lib/util'

describe 'util', ->

  describe 'walk', ->

    identity = (data) -> data

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
    ]

    for test in tests
      do (test) ->
        {description, input, expected, fn} = test
        it description, ->
          result = walk input, fn
          result.should.eql expected
