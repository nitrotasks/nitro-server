should = require 'should'
{define, defineFn, reset} = require '../app/utils/validation'

describe 'Validation', ->


  it 'should define a native type', ->

    test = define 'native_type', 'number'

    test(38).should.be.true
    test(-1).should.be.true

    test('').should.be.false
    test({}).should.be.false
    test([]).should.be.false


  it 'should not allow definitions to reuse the same name', ->

    define 'name_a', 'string'
    ( -> define 'name_a', 'number' ).should.fail


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

    define 'box', 'object',
      inherit: 'model'
      keys:
        width: 'number'
        height: 'number'

    test = define 'special_box', 'object',
      inherit: 'box'
      keys:
        color: 'string'

    test({
      id: 20
      name: 'Box'
      width: 20
      height: 30
      color: 'red'
    }).should.be.true


  it 'should override inherited properties', ->

    define 'test_model', 'object',
      inherit: 'model'
      keys:
        id: 'string'
        list: 'string'

    test = define 'test_test_model', 'object',
      inherit: 'test_model'
      keys:
        name: 'array'
        list: 'number'

    test({
      id: 's20'
      name: ['test']
      list: 30
    }).should.be.true

    test({
      id: 20
      list: 'c20'
      name: 'fail'
    }).should.be.false


 it 'should test indexes of an array', ->

   test = define 'test_array', 'array',
     keys:
       0: 'string'
       1: 'number'

    test(['a string', 20]).should.be.true
    test([20, 'string']).should.be.false
