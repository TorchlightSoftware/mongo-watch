logger = require 'ale'
should = require 'should'
filterDelta = require '../lib/filterDelta'

fullEvent =
  email: 'graham@daventry.com'
  father:
    name: 'John'
    occupation: 'Vacuum cleaner salesman'
  friends: [
      name: 'Bob'
      loginCount: 5
    ,
      name: 'Jane'
      loginCount: 3
  ]
  _id: '51e070258c3add6c75000001'

updateEvent =
  $set: {name: 'Graham', status: 'online'}
  $inc: {loginCount: 1}

describe 'filter delta', ->
  tests = [
      description: 'select email'
      input: fullEvent
      select: {email: true}
      output: {email: 'graham@daventry.com'}
    ,
      description: 'select all'
      input: fullEvent
      select: true
      output: fullEvent
    ,
      description: 'select none'
      input: fullEvent
      select: false
      output: undefined
    ,
      description: 'select nested'
      input: fullEvent
      select:
        father:
          name: true
      output:
        father:
          name: 'John'
    ,
      description: 'select array field'
      input: fullEvent
      select:
        friends:
          name: true
      output:
        friends: [{name: 'Bob'}, {name: 'Jane'}]
    ,
      description: 'over-select'
      input: fullEvent
      select:
        email: true
        hobbies: true
      output:
        email: 'graham@daventry.com'
    ,
      description: 'select name from update'
      input: updateEvent
      select:
        name: true
      output:
        $set: {name: 'Graham'}
    ,
  ]

  for test in tests
    do (test) ->
      {description, input, select, output} = test
      it description, ->
        result = filterDelta input, select
        if output?
          result.should.eql output
        else
          should.not.exist result
