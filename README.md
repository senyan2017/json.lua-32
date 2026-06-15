# ![json.lua](https://cloud.githubusercontent.com/assets/3920290/9281532/99e5e0cc-42bd-11e5-8fce-eaff2f7fc681.png)
A lightweight JSON library for Lua


## Features
* Implemented in pure Lua: works with 5.1, 5.2, 5.3 and JIT
* Fast: generally outperforms other pure Lua JSON implementations
  ([benchmark scripts](bench/))
* Tiny: around 280sloc, 9kb
* Proper error messages, *eg:* `expected '}' or ',' at line 203 col 30`


## Usage
The [json.lua](json.lua?raw=1) file should be dropped into an existing project
and required by it:
```lua
json = require "json"
```
The library provides the following functions:

#### json.encode(value)
Returns a string representing `value` encoded in JSON.
```lua
json.encode({ 1, 2, 3, { x = 10 } }) -- Returns '[1,2,3,{"x":10}]'
```

#### json.decode(str)
Returns a value representing the decoded JSON string.
```lua
json.decode('[1,2,3,{"x":10}]') -- Returns { 1, 2, 3, { x = 10 } }
```

#### json.null
A sentinel value used to represent JSON `null` inside decoded arrays and objects.
Use it when checking decoded values or when encoding a Lua table back to JSON.
```lua
local value = json.decode('{"items":[1,null],"meta":{"next":null}}')

value.items[2] == json.null   -- true
value.meta.next == json.null  -- true

json.encode({ items = { 1, json.null }, meta = { next = json.null } })
-- Returns '{"items":[1,null],"meta":{"next":null}}'
```

## Notes
* Trying to encode values which are unrepresentable in JSON will never result
  in type conversion or other magic: sparse arrays, tables with mixed key types
  or invalid numbers (NaN, -inf, inf) will raise an error
* Decoding `null` at the top level, inside an array, or inside an object returns
  `json.null`, so explicit null values can survive a decode → encode round trip
* Lua `nil` still encodes as JSON `null`, but decoded JSON `null` values are
  represented as `json.null` so they can be distinguished from missing fields
* *Pretty* encoding is not supported, `json.encode()` only encodes to a compact
  format


## License
This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.
