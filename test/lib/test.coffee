assert = require 'assert'

buildSpecials = require '../../lib/index.coffee'
{Specials, Special} = buildSpecials

describe 'test Specials', ->

  it 'should build', -> assert buildSpecials()


  it 'allows types option', ->

    specials = buildSpecials types: {custom:true}
    assert.equal specials.types.custom, true


  it 'adds a type', ->

    specials = buildSpecials()
    specials.addType 'test', {some:'options'}
    assert specials.types.test
    assert.equal specials.types.test.some, 'options'


  it '"gets" type by name', ->

    specials = buildSpecials()
    specials.addType 'test', type:true
    assert.deepEqual specials.type('test'), type:true


  it 'can skip a property', ->

    specials = buildSpecials()
    creator = -> ignore:'me'
    enhancers = ignore:'skip'
    spec = specials.build 0, creator, enhancers
    assert spec
    assert spec.array
    assert spec.array[0]
    assert.deepEqual spec.array[0], key:'ignore', skip:true


  it 'can build a select type', ->

    specials = buildSpecials()
    specials.addType 'select', select:[ 'a', 'b', 'c' ]
    assert specials.types.select

    select = specials.types.select
    assert select.encode
    assert select.decode

    result = null
    enbyte = int: (value) -> result = value

    select.encode enbyte, 'a'
    assert.equal result, 0

    select.encode enbyte, 'b'
    assert.equal result, 1

    select.encode enbyte, 'c'
    assert.equal result, 2

    select.encode enbyte, 'd'
    assert.equal result, -1

    debyte = (index) -> int: (_, callback) -> callback index
    input = null

    assert.equal select.decode(debyte(0), input), 'a'
    assert.equal select.decode(debyte(1), input), 'b'
    assert.equal select.decode(debyte(2), input), 'c'
    assert.equal select.decode(debyte(-1), input), undefined


  it 'can build a simple Special with a simple property', ->

    creator = -> one:1

    specials = buildSpecials()
    spec = specials.build 7, creator
    assert spec
    assert.equal spec.id, 7
    assert.equal spec.creator, creator
    assert.deepEqual spec.array, [ { key:'one', default:1 } ]


  it 'can imprint a Special on an object', ->

    specials = buildSpecials()
    spec = specials.build 7, -> one:1
    object = {}
    assert.equal object[Special.KEY], undefined
    spec.imprint object
    assert.equal object[Special.KEY], spec


  it 'can imprint a Special on a prototype', ->

    class MyObject
      constructor: (@value) ->
    creator = -> value:'testing'
    specials = buildSpecials()
    spec = specials.build 7, creator

    spec.imprint MyObject.prototype
    instance = new MyObject 'blah'
    assert.equal instance[Special.KEY], spec


  it 'can build a Special with an inner generic object', ->

    creator = -> one:1, two: { inner: true }

    specials = buildSpecials()
    spec = specials.build 7, creator
    assert spec
    assert.equal spec.id, 7
    assert.equal spec.creator, creator
    assert.deepEqual spec.array, [
      { key:'one', default:1 }
      { key:'two', array: [ { key:'inner', default:true } ], default: {inner:true} }
    ]


  it 'can build a Special with an inner special object', ->

    specials = buildSpecials()

    creator1 = -> one:1
    spec1 = specials.build 7, creator1

    value2 = {}
    spec1.imprint value2
    creator2 = -> one:1, two: value2
    spec2 = specials.build 8, creator2

    assert spec2
    assert.equal spec2.id, 8
    assert.equal spec2.creator, creator2
    assert.deepEqual spec2.array, [
      { key:'one', default:1 }
      {
        key:'two'
        default: value2
        encode: Specials.prototype._specialEncode
        decode: Specials.prototype._specialDecode
      }
    ]

    enbyte = special: (value, output) -> value + ' ' + output
    assert.equal spec2.array[1].encode(enbyte, 'value', 'output'), 'value output'

    debyte = special: (input) -> 'input ' + input
    assert.equal spec2.array[1].decode(debyte, 'value'), 'input value'


  it 'can build a Special with a select enhancer', ->

    creator   = -> fruit:'apple'
    enhancers = fruit: select: [ 'orange', 'banana', 'apple', 'kiwi' ]

    specials = buildSpecials()

    spec = specials.build 7, creator, enhancers

    assert spec
    assert.equal spec.id, 7
    assert.equal spec.creator, creator
    assert spec.array
    assert.equal spec.array.length, 1
    assert.equal spec.array[0].key, 'fruit'
    assert.equal spec.array[0].default, 'apple'

    assert spec.array[0]
    assert spec.array[0].encode

    result = null
    enbyte = int: (value) -> result = value

    assert.equal spec.array[0].encode(enbyte, 'orange'), 0
    assert.equal spec.array[0].encode(enbyte, 'banana'), 1
    assert.equal spec.array[0].encode(enbyte, 'apple'), 2
    assert.equal spec.array[0].encode(enbyte, 'kiwi'), 3

    assert spec.array[0].decode

    debyte = (index) -> int: (_, callback) -> callback index
    input = null

    assert.equal spec.array[0].decode(debyte(0), input), 'orange'
    assert.equal spec.array[0].decode(debyte(1), input), 'banana'
    assert.equal spec.array[0].decode(debyte(2), input), 'apple'
    assert.equal spec.array[0].decode(debyte(3), input), 'kiwi'


  it 'can build a Special with an encode/decode enhancer', ->

    creator = -> fruit: 'apple'

    enhancers =
      fruit:
        encode: (enbyte, value, _) -> 'encoded ' + value
        decode: (debyte, input) -> 'decoded'

    specials = buildSpecials()

    spec = specials.build 7, creator, enhancers

    assert spec
    assert.equal spec.id, 7
    assert.equal spec.creator, creator
    assert spec.array
    assert.equal spec.array.length, 1
    assert.equal spec.array[0].key, 'fruit'
    assert.equal spec.array[0].default, 'apple'

    assert spec.array[0]
    assert spec.array[0].encode

    assert.equal spec.array[0].encode(null, 'orange'), 'encoded orange'
    assert.equal spec.array[0].encode(null, 'banana'), 'encoded banana'
    assert.equal spec.array[0].encode(null, 'apple'), 'encoded apple'
    assert.equal spec.array[0].encode(null, 'kiwi'), 'encoded kiwi'

    assert spec.array[0].decode

    assert.equal spec.array[0].decode(null, null), 'decoded'


  it 'can build a Special with a shared encode/decode enhancer', ->

    specials = buildSpecials()

    specials.addType 'fruit',
      encode: (enbyte, value, _) -> 'encoded ' + value
      decode: (debyte, input) -> 'decoded'

    creator = -> fruit: 'apple'
    enhancers = fruit: 'fruit'

    spec = specials.build 7, creator, enhancers

    assert spec
    assert.equal spec.id, 7
    assert.equal spec.creator, creator
    assert spec.array
    assert.equal spec.array.length, 1
    assert.equal spec.array[0].key, 'fruit'
    assert.equal spec.array[0].default, 'apple'

    assert spec.array[0]
    assert spec.array[0].encode

    assert.equal spec.array[0].encode(null, 'orange'), 'encoded orange'
    assert.equal spec.array[0].encode(null, 'banana'), 'encoded banana'
    assert.equal spec.array[0].encode(null, 'apple'), 'encoded apple'
    assert.equal spec.array[0].encode(null, 'kiwi'), 'encoded kiwi'

    assert spec.array[0].decode

    assert.equal spec.array[0].decode(null, null), 'decoded'


  it 'can build a Special with a local enhancer overriding a shared enhancer', ->

    specials = buildSpecials()

    specials.addType 'fruit',
      encode: (enbyte, value, _) -> 'shared encoded ' + value
      decode: (debyte, input) -> 'shared decoded'

    creator = -> fruit: 'apple'
    enhancers =
      fruit:
        type: 'fruit'
        encode: (enbyte, value, _) -> 'override encoded ' + value
        decode: (debyte, input) -> 'override decoded'

    spec = specials.build 7, creator, enhancers

    assert spec
    assert.equal spec.id, 7
    assert.equal spec.creator, creator
    assert spec.array
    assert.equal spec.array.length, 1
    assert.equal spec.array[0].key, 'fruit'
    assert.equal spec.array[0].default, 'apple'

    assert spec.array[0]
    assert spec.array[0].encode

    assert.equal spec.array[0].encode(null, 'orange'), 'override encoded orange'
    assert.equal spec.array[0].encode(null, 'banana'), 'override encoded banana'
    assert.equal spec.array[0].encode(null, 'apple'), 'override encoded apple'
    assert.equal spec.array[0].encode(null, 'kiwi'), 'override encoded kiwi'

    assert spec.array[0].decode

    assert.equal spec.array[0].decode(null, null), 'override decoded'


  it 'can build a Special with an empty encode/decode enhancer', ->

    creator = -> fruit: 'apple'

    enhancers =
      fruit:
        nada: true

    specials = buildSpecials()

    spec = specials.build 7, creator, enhancers

    assert spec
    assert.equal spec.id, 7
    assert.equal spec.creator, creator
    assert spec.array
    assert.equal spec.array.length, 1
    assert.equal spec.array[0].key, 'fruit'
    assert.equal spec.array[0].default, 'apple'

    assert spec.array[0]
    assert.equal spec.array[0].encode, null
    assert.equal spec.array[0].decode, null
