# @endeo/specials
[![Build Status](https://travis-ci.org/elidoran/endeo-specials.svg?branch=master)](https://travis-ci.org/elidoran/endeo-specials)
[![Dependency Status](https://gemnasium.com/elidoran/endeo-specials.png)](https://gemnasium.com/elidoran/endeo-specials)
[![npm version](https://badge.fury.io/js/%40endeo%2Fspecials.svg)](http://badge.fury.io/js/%40endeo%2Fspecials)
[![Coverage Status](https://coveralls.io/repos/github/elidoran/endeo-specials/badge.svg?branch=master)](https://coveralls.io/github/elidoran/endeo-specials?branch=master)

Build "object spec" for compact object encoding.

A flexible specification allowing progressive improvements for greater performance.

Features:

1. knows a list of **property names** for an object to allow encoding without them which **avoids all those bytes**.
2. optionally knows **defaults** to avoid encoding those values.
3. optionally knows **type** to avoid the value's **type check** every time for faster encoding and decoding.
4. optionally uses **special keys** to trigger automatic encoding/decoding changes for compression (or any reason). You may define your own special keys and how they are used.

See packages:

1. [endeo](https://www.npmjs.com/package/endeo)
2. [enbyte](https://www.npmjs.com/package/enbyte)
3. [debyte](https://www.npmjs.com/package/debyte)
4. [unstring](https://www.npmjs.com/package/unstring)


## Install

```sh
npm install --save @endeo/specials
```


## Usage


```javascript
// get the Specials builder
var build = require('@endeo/specials')

// the types we'd like to refer to by name.
// i'm using some default ones.
var types = require('@endeo/types')

// build it
var specials = build({ types: types })

// add more types:
specials.addType('someId', {
  // optionally provide one or both
  encode: function(enbyte, value, output) {},
  decode: function(debyte, input) {}
})

// add a type which is always one of a set of values
specials.addType('fruit', {
  // basically encodes the index of the value
  select: [ 'apple', 'banana', 'orange' ]
})

// a "creator" function makes an object
// representing the object with all its keys
// and default values.
function createThing() {
  return {
    key1: 'someDefault',
    key2: 2,
    fruit: 'banana'
  }
}

// the "enhancers" are extra info you can supply
var enhancers = {
  key1: 'name of a type',
  key2: {
    // optionally ref a known type still
    type: 'name of a type',

    // optionally provide encode() / decode()
    encode: function(enbyte, value, output) {},
    decode: function(debyte, input) {}
  },
  fruit: 'fruit' // use type 'fruit' above
}

// create an "object spec" (Special)
var spec = specials.build(1, createThing, enhancers)

// set the spec's ID on your objects.

// on a class:
function SomeClass() {}
spec.imprint(SomeClass.prototype)

// on an object:
var someObject = {}
spec.imprint(someObject)
```


# [MIT License](LICENSE)
