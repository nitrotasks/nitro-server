should = require 'should'
{define, defineFn} = require '../app/utils/validation'

describe 'Validation', ->

  it 'should define a native type', ->

    test = define 'int', 'number'

    test(38).should.be.true
    test(-1).should.be.true

    test('').should.not.be.true
    test({}).should.not.be.true
    test([]).should.not.be.true

  it 'should define a basic object', ->

    test = define 'basic_object', 'object',
      keys:
        id: 'number'
        name: 'string'

    test({
      id: 20
      name: 'A string'
    }).should.be.true

    test({
      id: 10
    }).should.be.true

    test({
      name: 'word'
    }).should.be.true

    test({}).should.be.true

    test({
      id: 30
      name: 'test'
      other: 'prop'
    }).should.not.be.true

    test([]).should.not.be.true

