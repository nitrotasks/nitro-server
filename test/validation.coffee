should = require 'should'
{define, defineFn} = require '../app/utils/validation'

describe 'Validation', ->

  it 'should define a native type', ->

    test = define 'native_type', 'number'

    test(38).should.be.true
    test(-1).should.be.true

    test('').should.be.false
    test({}).should.be.false
    test([]).should.be.false

  it 'should know the difference between an object and an array', ->

    test = define 'array_test', 'array'

    test([]).should.be.true
    test({}).should.be.false

    test = define 'object_test', 'object'

    test({}).should.be.true
    test([]).should.be.false

    test = define 'native_object', '*object'

    test({}).should.be.true
    test([]).should.be.true

  it 'should define a basic object', ->

    test = define 'basic_object', 'object',
      keys:
        id: 'number'
        name: 'string'

    # Full match
    test({
      id: 20
      name: 'A string'
    }).should.be.true

    # Partial properties
    test({ id: 10 }).should.be.true
    test({ name: 'word' }).should.be.true

    # Objects vs arrays
    test([]).should.be.false
    test({}).should.be.true

    # Extra properties should mark it as invalid
    test({
      id: 30
      name: 'test'
      other: 'prop'
    }).should.be.false

  it 'should inherit properties from other definitions', ->

    define 'model', 'object',
      keys:
        id: 'number'
        name: 'string'

    test = define 'box', 'object',
      inherit: 'model'
      keys:
        width: 'number'
        height: 'number'

    test({
      id: 20
      name: 'Box 1'
      width: 20
      height: 30
    }).should.be.true
        

