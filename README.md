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

#### json.encode(value [, opts])
Returns a string representing `value` encoded in JSON.
```lua
json.encode({ 1, 2, 3, { x = 10 } }) -- Returns '[1,2,3,{"x":10}]'
```
Pass `true` (or an options table) as the second argument to get *pretty*,
human-readable output with indentation, newlines and stable (sorted) object
keys -- handy for config files, logs and reviewing diffs:
```lua
json.encode({ x = 1, y = 2 }, true)
-- Returns:
-- {
--   "x": 1,
--   "y": 2
-- }
```
The compact, single-line output is unaffected and remains the default. The
options table accepts:
* `pretty` &mdash; enable pretty output (implied when `indent`/`newline` is given)
* `indent` &mdash; a string, or a number of spaces, used per nesting level (default `2`)
* `newline` &mdash; the line separator (default `"\n"`)
```lua
json.encode({ a = 1 }, { indent = "\t", newline = "\r\n" })
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
* *Pretty* encoding is opt-in: `json.encode(value)` encodes to a compact format
  by default, while `json.encode(value, true)` (or an options table) produces
  indented, human-readable output with stable object key ordering


## License
This library is free software; you can redistribute it and/or modify it under
the terms of the MIT license. See [LICENSE](LICENSE) for details.

