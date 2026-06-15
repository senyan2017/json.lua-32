
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


-------------------------------------------------------------------------------
-- Pretty Encode Tests
-------------------------------------------------------------------------------

test("pretty encode scalars", function()
  assert( json.encode_pretty(42) == "42" )
  assert( json.encode_pretty(0) == "0" )
  assert( json.encode_pretty(-3.14) == "-3.14" )
  assert( json.encode_pretty("hello") == [["hello"]] )
  assert( json.encode_pretty("") == [[""]] )
  assert( json.encode_pretty(true) == "true" )
  assert( json.encode_pretty(false) == "false" )
  assert( json.encode_pretty(nil) == "null" )
end)


test("pretty encode empty", function()
  -- Empty table encodes as empty array (consistent with compact encode)
  assert( json.encode_pretty({}) == "[]" )
end)


test("pretty encode array", function()
  local res = json.encode_pretty({ 1, 2, 3 })
  local expected = "[\n  1,\n  2,\n  3\n]"
  assert( res == expected, fmt("expected:\n%s\ngot:\n%s", expected, res) )
end)


test("pretty encode nested array", function()
  local res = json.encode_pretty({ {1, 2}, {3, 4} })
  local expected = "[\n  [\n    1,\n    2\n  ],\n  [\n    3,\n    4\n  ]\n]"
  assert( res == expected, fmt("expected:\n%s\ngot:\n%s", expected, res) )
end)


test("pretty encode object", function()
  local res = json.encode_pretty({ x = 10, y = 20 })
  -- Keys must be sorted alphabetically
  local expected = '{\n  "x": 10,\n  "y": 20\n}'
  assert( res == expected, fmt("expected:\n%s\ngot:\n%s", expected, res) )
end)


test("pretty encode key order stable", function()
  -- Two tables with same content but different insertion order must match
  local a = { z = 1, a = 2, m = 3 }
  local b = { a = 2, m = 3, z = 1 }
  assert( json.encode_pretty(a) == json.encode_pretty(b),
          "pretty encode output is not stable for same object content" )
  -- Verify alphabetical order
  local res = json.encode_pretty(a)
  local ai = res:find('"a"')
  local mi = res:find('"m"')
  local zi = res:find('"z"')
  assert( ai < mi and mi < zi, "keys are not in alphabetical order" )
end)


test("pretty encode nested object", function()
  local val = { name = "test", info = { id = 1, active = true } }
  local res = json.encode_pretty(val)
  assert( res:find('"active"') < res:find('"id"'), "nested keys not sorted" )
  assert( res:find('"id"') < res:find('"name"'), "top-level keys not sorted" )
  -- Round-trip: decode pretty output must match original
  local decoded = json.decode(res)
  assert( decoded.name == "test" )
  assert( decoded.info.id == 1 )
  assert( decoded.info.active == true )
end)


test("pretty encode mixed", function()
  local val = { items = { 1, 2, 3 }, label = "data" }
  local res = json.encode_pretty(val)
  -- Decode and verify
  local decoded = json.decode(res)
  assert( equal(decoded, val), "round-trip failed for mixed array/object" )
end)


test("pretty encode custom indent", function()
  -- 4-space indent
  local res = json.encode_pretty({ a = 1 }, { indent = "    " })
  assert( res:find("    \"a\"") ~= nil, "custom 4-space indent not applied" )

  -- Tab indent
  local res = json.encode_pretty({ a = 1 }, { indent = "\t" })
  assert( res:find("\t\"a\"") ~= nil, "custom tab indent not applied" )
end)


test("pretty encode custom newline", function()
  local res = json.encode_pretty({ 1, 2 }, { newline = "\r\n" })
  assert( res:find("\r\n") ~= nil, "custom newline not applied" )
end)


test("pretty encode custom separator", function()
  local res = json.encode_pretty({ a = 1 }, { separator = ":" })
  assert( res:find('"a":1') ~= nil, "custom separator not applied" )
end)


test("pretty encode deep nesting", function()
  local val = { a = { b = { c = { d = "deep" } } } }
  local res = json.encode_pretty(val)
  -- Check indentation levels: d should be at 4 levels = 8 spaces
  assert( res:find("        \"d\"") ~= nil, "deep nesting indentation wrong" )
  -- Round-trip
  local decoded = json.decode(res)
  assert( equal(decoded, val), "round-trip failed for deep nesting" )
end)


test("pretty encode invalid", function()
  local t = {
    { [1000] = "b" },          -- sparse array
    { [function() end] = 12 }, -- invalid key type
    { nil, 2, 3, 4 },          -- sparse array
    { x = 10, [1] = 2 },       -- mixed key types
  }
  for i, v in ipairs(t) do
    local status = pcall(json.encode_pretty, v)
    assert( not status, fmt("pretty encoding idx %d did not result in an error", i) )
  end
end)


test("pretty encode invalid number", function()
  local t = {
    math.huge,      -- inf
    -math.huge,     -- -inf
    math.huge * 0,  -- NaN
  }
  for i, v in ipairs(t) do
    local status = pcall(json.encode_pretty, v)
    assert( not status, fmt("pretty encoding '%s' did not result in an error", v) )
  end
end)


test("pretty encode circular", function()
  local t = {}
  t.self = t
  local status = pcall(json.encode_pretty, t)
  assert( not status, "circular reference was not detected" )
end)


test("pretty encode preserves compact", function()
  -- Ensure json.encode is not affected by encode_pretty
  local compact = json.encode({ 1, 2, 3, { x = 10 } })
  assert( compact == '[1,2,3,{"x":10}]',
          fmt("compact encode changed: got '%s'", compact) )
end)
