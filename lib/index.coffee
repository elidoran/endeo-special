# TODO:
#  accept `$order$` property in enhancers to allow specifying the order of keys.
#  this allows controlling their order explicitly for various reasons.
#  might want to load the end with things needing SUB_TERMINATOR and then
#  end them all at once with a single TERMINATOR (collapse),

# an "object spec" for a "special object".
# it knows the properties of an object so we can encode it
# without the property names, and more.
class Special

  @KEY: '$ENDEO_SPECIAL'

  constructor: (options) ->

    @id      = options.id
    @creator = options.creator
    @array   = options.array


  imprint: (object) ->

    Object.defineProperty object, Special.KEY,
      configurable: false
      enumerable  : false
      writable    : false
      value       : this  # set this `spec` in there

    return



# knows special types to use when building an "object spec" (Special)
class Specials

  constructor: (options) ->

    # put the default types into @endeo/types ?
    @types = options?.types ? Object.create null


  addType: (name, options) ->

    # usually supplies encode/decode functions.
    # might have a `select` tho.
    @types[name] =
      if options.select? then @types[name] = @_select options.select
      else options


  type: (name) -> @types[name]


  build: (id, creator, enhancers) ->

    # 1. first, build the info object
    info = creator()

    # 2. get the "spec array" via analyzing `info`
    array = @analyze info, enhancers

    # 3. build an ObjectSpec to wrap those two
    # TODO: we could put the `id` into the `array` at front ...
    #       probably better not to.
    new Special {id, creator, array}


  #
  analyze: (object, enhancers) ->

    # 1. after in-place changes this array will also be used for
    #    iterating thru during encode/decode.
    keys = Object.keys(object).sort()

    # 2. analyze each key and replace it with its "spec info"
    for key, index in keys

      value = object[key]

      # # info: key, default, array, encode, decode, skip

      # info 1 - it always has `key`
      keys[index] = info = {key}

      # info 6 - handle the "special enhancer": 'skip'
      # TODO: if multiple skips in a row, use special bytes, SKIP5, SKIPN, ...
      enhancer = enhancers?[key]
      if enhancer is 'skip'
        info.skip = true
        continue

      # info 2: the value provided is the default value
      info.default = value

      # if the value is an object then we need to analyze it as well.
      # NOTE: check null first cuz null's typeof is object.
      if value? and typeof value is 'object' and not Array.isArray value

        if value[Special.KEY]?  # special object
          # info 4 + 5:
          info.encode = @_specialEncode
          info.decode = @_specialDecode

        # generic object, so learn its props as part of our spec.
        # info 3:
        else info.array = @analyze value, enhancers?[key]

      # when it's not an object then there's more to do
      else

        # the `enhancers` may have something for this key
        # info 4 + 5: maybe
        if enhancer? then @_enhance info, enhancer

      # we're all done configuring the `info` for this key.

    # all done analyzing keys and genering info.
    return keys

  _specialEncode: (enbyte, value, output) -> enbyte.special value, output
  _specialDecode: (debyte, input) -> debyte.special input


  _select: (array) ->
    encode: (enbyte, value, _) -> enbyte.int array.indexOf value
      # index = array.indexOf value
      # if index > -1 then enbyte.int index else -1 error:'unknown value', value:value
    decode: (debyte, input) -> debyte.int input, (index) -> array[index]


  _enhance: (info, enhancer) ->

    # may be a reference to a common one, may want to be combined...
    enhance =

      # if it's a string then get the common (stored) info
      if typeof enhancer is 'string' then @types[enhancer]

      # if it's a sub-property then combine the common with this
      else if enhancer.type? then Object.assign {}, @types[enhancer.type], enhancer

      # else use it as-is
      else enhancer

    # if it has a `select` property then make encoder/decoder for that
    if enhance.select?
      select = @_select enhance.select
      info.encode = select.encode
      info.decode = select.decode

    else # use for info (if they exist) # TODO: error ?
      info.encode = enhance.encode if enhance.encode?
      info.decode = enhance.decode if enhance.decode?
      info.decoderNode = enhance.decoderNode if enhance.decoderNode?


module.exports = (options) -> new Specials options
module.exports.Specials = Specials
module.exports.Special = Special
