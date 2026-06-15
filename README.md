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

#### json.encode_pretty(value, [opts])
Returns a string representing `value` encoded in a human-readable JSON format
with indentation and newlines. Object keys are sorted alphabetically for
stable output. The optional `opts` table supports:
* `indent` — string for one indentation level (default `"  "` — 2 spaces)
* `newline` — string for line breaks (default `"\n"`)
* `separator` — string between key and value (default `": "`)
```lua
json.encode_pretty({ name = "John", age = 30, hobbies = {"reading", "coding"} })
-- Returns:
-- {
--   "age": 30,
--   "hobbies": [
--     "reading",
--     "coding"
--   ],
--   "name": "John"
-- }

-- Custom indentation (4 spaces):
json.encode_pretty(val, { indent = "    " })
-- Tab indentation:
json.encode_pretty(val, { indent = "\t" })
```

#### json.decode(str)
Returns a value representing the decoded JSON string.
```lua
json.decode('[1,2,3,{"x":10}]') -- Returns { 1, 2, 3, { x = 10 } }
```

## Notes
* Trying to encode values which are unrepresentable in JSON will never result
  in type conversion or other magic: sparse arrays, tables with mixed key types
  or invalid numbers (NaN, -inf, inf) will raise an error
* `null` values contained within an array or object are converted to `nil` and
  are therefore lost upon decoding
* `json.encode()` always produces compact output; use `json.encode_pretty()`
  for a human-readable format


## License
This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.

