should = require 'should'
{define, defineFn, undefine} = require '../app/utils/validation'

describe 'Validation', ->

  definitions = []

  _define = define

  define = (name, type, details) ->
    definitions.push name
    return _define(name, type, details)

  afterEach ->
    undefine name for name in definitions
    definitions = []

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


  it 'should allow excess keys', ->

    test = define 'other_object', 'object',
      keys:
        id: 'number'
        name: 'string'
      other: true

    test({
      id: 20
      name: 'name'
    }).should.be.true

    test({
      id: 20
      name: 'name'
      random: true
    }).should.be.true

    test({
      notevenclose: 'amazing'
    }).should.be.true

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

    define 'model_1', 'object',
      keys:
        id: 'number'
        name: 'string'

    define 'model_2', 'object',
      inherit: 'model_1'
      keys:
        id: 'string'
        list: 'string'

    test = define 'model_3', 'object',
      inherit: 'model_2'
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


  it 'should inherit with arrays', ->

    define 'array_1', 'array',
      keys:
        0: 'number'

    define 'array_2', 'array',
      inherit: 'array_1'
      keys:
        1: 'string'

    test = define 'array_3', 'array',
      inherit: 'array_2'
      keys:
        2: 'object'

    test([20, 'word', {}]).should.be.true


  it 'should be able to use custom child classes', ->

    define 'child', 'object',
      keys:
        id: 'number'
        name: 'string'

    test = define 'parent', 'object',
      keys:
        name: 'string'
        child: 'child'

    test({
      name: 'word'
    }).should.be.true

    test({
      name: 20
    }).should.be.false

    test({
      name: 'A name'
      child: {
        id: 20
        name: 'no'
      }
    }).should.be.true

    test({
      child: {
        name: 30
      }
    }).should.be.false

    test({
      child:
        random: false
    }).should.be.false

  it 'should use a custom function to check', ->

    define 'test', 'object', (obj) ->
      

