
local json = loadfile("../json.lua")()


local fmt = string.format

local function test(name, func)
  xpcall(function()
    func()
    print( fmt("[pass] %s", name) )
  end, function(err)
    print( fmt("[fail] %s : %s", name, err) )
  end)
end


local function equal(a, b)
  -- Handle table
  if type(a) == "table" and type(b) == "table" then
    for k in pairs(a) do
      if not equal(a[k], b[k]) then
        return false
      end
    end
    for k in pairs(b) do
      if not equal(b[k], a[k]) then
        return false
      end
    end
    return true
  end
  -- Handle scalar
  return a == b
end


test("numbers", function()
  local t = {
    [ "123.456"       ] = 123.456,
    [ "-123"          ] = -123,
    [ "-567.765"      ] = -567.765,
    [ "12.3"          ] = 12.3,
    [ "0"             ] = 0,
    [ "0.10000000012" ] = 0.10000000012,
  }
  for k, v in pairs(t) do
    local res = json.decode(k)
    assert( res == v, fmt("expected '%s', got '%s'", k, res) )
    local res = json.encode(v)
    assert( res == k, fmt("expected '%s', got '%s'", v, res) )
  end
  assert( json.decode("13e2") == 13e2 )
  assert( json.decode("13E+2") == 13e2 )
  assert( json.decode("13e-2") == 13e-2 )
end)


test("literals", function()
  assert( json.decode("true") == true )
  assert( json.encode(true) == "true" )
  assert( json.decode("false") == false )
  assert( json.encode(false) == "false" )
  assert( json.decode("null") == nil )
  assert( json.encode(nil) == "null")
end)


test("strings", function()
  local s = ""
  assert( s == json.decode( json.encode(s) ) )
  local s = "\\"
  assert( s == json.decode( json.encode(s) ) )
  local s = "Hello world"
  assert( s == json.decode( json.encode(s) ) )
  local s = "\0 \13 \27"
  assert( s == json.decode( json.encode(s) ) )
  local s = "\0\r\n\8"
  assert( s == json.decode( json.encode(s) ) )
end)


test("unicode", function()
  local s = "こんにちは世界"
  assert( s == json.decode( json.encode(s) ) )
end)


test("arrays", function()
  local t = { "cat", "dog", "owl" }
  assert( equal( t, json.decode( json.encode(t) ) ) )
end)


test("objects", function()
  local t = { x = 10, y = 20, z = 30 }
  assert( equal( t, json.decode( json.encode(t) ) ) )
end)


--test("strict decode", function()
--  local t = {
--    '{x : 1}',
--    '{x : hello}',
--    "{'x' : 1}",
--    '{"x" : nil}',
--    '{"x" : 0x10}',
--    '{"x" : 001}',
--    '{"x" : .1}',
--    '{"x" : 1, }',
--    '[1, 2, 3, ]',
--  }
--  for i, v in ipairs(t) do
--    local status = pcall(json.decode, v)
--    assert( not status, fmt("'%s' was parsed without error", v) )
--  end
--end)


test("decode invalid", function()
  local t = {
    '',
    ' ',
    '{',
    '[',
    '{"x" : ',
    '{"x" : 1',
    '{"x" : z }',
    '{"x" : 123z }',
    '{x : 123 }',
    '{10 : 123 }',
    '{]',
    '[}',
    '"a',
    '10 xx',
    '{}123'
  }
  for i, v in ipairs(t) do
    local status = pcall(json.decode, v)
    assert( not status, fmt("'%s' was parsed without error", v) )
  end
end)


test("decode invalid string", function()
  local t = {
    [["\z"]],
    [["\1"]],
    [["\u000z"]],
    [["\ud83d\ude0q"]],
    '"x\ny"',
    '"x\0y"',
  }
  for i, v in ipairs(t) do
    local status, err = pcall(json.decode, v)
    assert( not status, fmt("'%s' was parsed without error", v) )
  end
end)


test("decode escape", function()
  local t = {
    [ [["\u263a"]]        ] = '☺',
    [ [["\ud83d\ude02"]]  ] = '😂',
    [ [["\r\n\t\\\""]]    ] = '\r\n\t\\"',
    [ [["\\"]]            ] = '\\',
    [ [["\\\\"]]          ] = '\\\\',
    [ [["\/"]]            ] = '/',
    [ [["\\u \u263a"]]  ] = [[\u ☺]],
  }
  for k, v in pairs(t) do
    local res = json.decode(k)
    assert( res == v, fmt("expected '%s', got '%s'", v, res) )
  end
end)


test("decode empty", function()
  local t = {
    [ '[]' ] = {},
    [ '{}' ] = {},
    [ '""' ] = "",
  }
  for k, v in pairs(t) do
    local res = json.decode(k)
    assert( equal(res, v), fmt("'%s' did not equal expected", k) )
  end
end)


test("decode collection", function()
  local t = {
    [ '[1, 2, 3, 4, 5, 6]'            ] = {1, 2, 3, 4, 5, 6},
    [ '[1, 2, 3, "hello"]'            ] = {1, 2, 3, "hello"},
    [ '{ "name": "test", "id": 231 }' ] = {name = "test", id = 231},
    [ '{"x":1,"y":2,"z":[1,2,3]}'     ] = {x = 1, y = 2, z = {1, 2, 3}},
  }
  for k, v in pairs(t) do
    local res = json.decode(k)
    assert( equal(res, v), fmt("'%s' did not equal expected", k) )
  end
end)


test("encode invalid", function()
  local t = {
    { [1000] = "b" },
    { [ function() end ] = 12 },
    { nil, 2, 3, 4 },
    { x = 10, [1] = 2 },
    { [1] = "a", [3] = "b" },
    { x = 10, [4] = 5 },
  }
  for i, v in ipairs(t) do
    local status, res = pcall(json.encode, v)
    assert( not status, fmt("encoding idx %d did not result in an error", i) )
  end
end)


test("encode invalid number", function()
  local t = {
    math.huge,      -- inf
    -math.huge,     -- -inf
    math.huge * 0,  -- NaN
  }
  for i, v in ipairs(t) do
    local status, res = pcall(json.encode, v)
    assert( not status, fmt("encoding '%s' did not result in an error", v) )
  end
end)


test("encode escape", function()
  local t = {
    [ '"x"'       ] = [["\"x\""]],
    [ 'x\ny'      ] = [["x\ny"]],
    [ 'x\0y'      ] = [["x\u0000y"]],
    [ 'x\27y'     ] = [["x\u001by"]],
    [ '\r\n\t\\"' ] = [["\r\n\t\\\""]],
  }
  for k, v in pairs(t) do
    local res = json.encode(k)
    assert( res == v, fmt("'%s' was not escaped properly", k) )
  end
end)


-- Regression tests for refactoring: error messages, edge cases, round-trips

test("error line/col reporting", function()
  -- Error at line 1 col 1 (empty input)
  local ok, err = pcall(json.decode, "")
  assert(not ok)
  assert(err:match("line 1 col 1"), fmt("expected line 1 col 1, got: %s", err))

  -- Error on second line
  local ok, err = pcall(json.decode, '{\n"x": }')
  assert(not ok)
  assert(err:match("line 2"), fmt("expected line 2 error, got: %s", err))

  -- Trailing garbage reports correct position
  local ok, err = pcall(json.decode, '123 abc')
  assert(not ok)
  assert(err:match("trailing garbage"), fmt("expected trailing garbage, got: %s", err))
end)


test("circular reference detection", function()
  local t = {}
  t[1] = t
  local ok, err = pcall(json.encode, t)
  assert(not ok)
  assert(err:match("circular reference"), fmt("expected circular reference, got: %s", err))
end)


test("deeply nested structures", function()
  -- Build a deeply nested array: [[[[...1...]]]]
  local depth = 50
  local s = string.rep("[", depth) .. "1" .. string.rep("]", depth)
  local res = json.decode(s)
  -- Unwrap and verify
  for i = 1, depth do
    assert(type(res) == "table")
    res = res[1]
  end
  assert(res == 1)

  -- Round-trip: encode then decode
  local deep = 1
  for i = 1, depth do
    deep = { deep }
  end
  local encoded = json.encode(deep)
  local decoded = json.decode(encoded)
  local val = decoded
  for i = 1, depth do
    val = val[1]
  end
  assert(val == 1)
end)


test("round-trip complex object", function()
  local obj = {
    name = "test",
    version = 1.5,
    active = true,
    tags = { "a", "b", "c" },
    nested = {
      x = nil,
      y = { z = "deep" },
      list = { 1, 2, 3 },
    },
    empty_obj = {},
    empty_arr = {},
    unicode = "こんにちは",
    special = "line1\nline2\ttab\\slash\"quote",
  }
  -- Note: empty tables default to array encoding, so empty_obj/empty_arr both become []
  local encoded = json.encode(obj)
  local decoded = json.decode(encoded)
  assert(decoded.name == "test")
  assert(decoded.version == 1.5)
  assert(decoded.active == true)
  assert(equal(decoded.tags, { "a", "b", "c" }))
  assert(decoded.nested.y.z == "deep")
  assert(equal(decoded.nested.list, { 1, 2, 3 }))
  assert(decoded.unicode == "こんにちは")
  assert(decoded.special == "line1\nline2\ttab\\slash\"quote")
end)


test("decode whitespace handling", function()
  -- Various whitespace around tokens
  assert(json.decode("  42  ") == 42)
  assert(json.decode("\t\n\r 42 \t\n\r") == 42)
  assert(equal(json.decode("  [ 1 , 2 , 3 ]  "), {1, 2, 3}))
  assert(equal(json.decode('  {  "a"  :  1  ,  "b"  :  2  }  '), {a = 1, b = 2}))
end)


test("encode type error messages", function()
  local ok, err = pcall(json.encode, function() end)
  assert(not ok)
  assert(err:match("unexpected type 'function'"),
    fmt("expected unexpected type error, got: %s", err))
end)


test("decode non-string argument", function()
  local ok, err = pcall(json.decode, 123)
  assert(not ok)
  assert(err:match("expected argument of type string"),
    fmt("expected type error, got: %s", err))

  local ok, err = pcall(json.decode, nil)
  assert(not ok)
  assert(err:match("expected argument of type string"))
end)


test("encode number edge cases", function()
  assert(json.encode(0) == "0")
  assert(json.encode(-0) == "0" or json.encode(-0) == "-0")  -- platform dependent
  assert(json.encode(1e100) == "1e+100" or json.encode(1e100) == "1e100"
    or json.encode(1e100) == "1.0e+100"
    or json.encode(1e100) == "1e100")
  -- Just verify it round-trips for reasonable numbers
  local nums = { 0.1, -0.1, 123456789, -123456789, 0.000001 }
  for _, n in ipairs(nums) do
    local decoded = json.decode(json.encode(n))
    assert(decoded == n, fmt("round-trip failed for %s", n))
  end
end)


test("decode number formats", function()
  assert(json.decode("0") == 0)
  assert(json.decode("-0") == 0)
  assert(json.decode("1e10") == 1e10)
  assert(json.decode("1E10") == 1e10)
  assert(json.decode("1e+10") == 1e10)
  assert(json.decode("1E+10") == 1e10)
  assert(json.decode("1e-10") == 1e-10)
  assert(json.decode("-1.5e2") == -1.5e2)
end)
