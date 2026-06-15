
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


test("encode compact unchanged", function()
  -- The default (no opts) compact encoder must keep its exact output
  assert( json.encode({ 1, 2, 3, { x = 10 } }) == '[1,2,3,{"x":10}]' )
  assert( json.encode({ x = 10 }) == '{"x":10}' )
  assert( json.encode(123.456) == "123.456" )
  assert( json.encode("a\nb") == [["a\nb"]] )
  -- A falsy/empty opts argument is treated as compact too
  assert( json.encode({ 1, 2, 3, { x = 10 } }, false) == '[1,2,3,{"x":10}]' )
  assert( json.encode({ 1, 2, 3, { x = 10 } }, {}) == '[1,2,3,{"x":10}]' )
  -- Compact output never contains pretty-printing whitespace
  local res = json.encode({ a = 1, b = 2, c = 3, d = { 4, 5 } })
  assert( not res:find("\n"), "compact output should not contain newlines" )
end)


test("encode pretty basic", function()
  assert( json.encode({ a = 1, b = 2, c = 3 }, true)
    == '{\n  "a": 1,\n  "b": 2,\n  "c": 3\n}' )
  assert( json.encode({ 1, 2, 3 }, true)
    == '[\n  1,\n  2,\n  3\n]' )
  assert( json.encode({ x = { y = 1 } }, true)
    == '{\n  "x": {\n    "y": 1\n  }\n}' )
  assert( json.encode({ name = "John", nums = { 1, 2 } }, true)
    == '{\n  "name": "John",\n  "nums": [\n    1,\n    2\n  ]\n}' )
  -- Empty tables match the compact form (no dangling whitespace)
  assert( json.encode({}, true) == "[]" )
  assert( json.encode({ a = {} }, true) == '{\n  "a": []\n}' )
end)


test("encode pretty roundtrip", function()
  local cases = {
    { 1, 2, 3, { x = 10 } },
    { name = "test", id = 231, ok = true, tags = { "a", "b" } },
    { x = 1, y = 2, z = { 1, 2, 3 } },
    { nested = { deep = { deeper = { "x\ny", "\t" } } } },
    {},
  }
  for i, v in ipairs(cases) do
    local enc = json.encode(v, true)
    assert( enc:find("\n") or next(v) == nil,
      fmt("pretty output for case %d should span multiple lines", i) )
    assert( equal( v, json.decode(enc) ),
      fmt("pretty roundtrip failed for case %d", i) )
  end
end)


test("encode pretty configurable indent", function()
  -- Default indent is two spaces, matching the library's concise style
  assert( json.encode({ a = 1 }, true) == '{\n  "a": 1\n}' )
  -- A numeric indent means that many spaces
  assert( json.encode({ a = 1 }, { indent = 4 }) == '{\n    "a": 1\n}' )
  assert( json.encode({ a = 1 }, { indent = 0 }) == '{\n"a": 1\n}' )
  -- A string indent is used verbatim (eg. tabs)
  assert( json.encode({ a = 1 }, { indent = "\t" }) == '{\n\t"a": 1\n}' )
  -- The indent is genuinely configurable, not hardwired to two spaces
  assert( json.encode({ a = 1 }, { indent = 4 }) ~= json.encode({ a = 1 }, true) )
end)


test("encode pretty configurable newline", function()
  assert( json.encode({ a = 1 }, { newline = "\r\n" }) == '{\r\n  "a": 1\r\n}' )
  assert( json.encode({ 1, 2 }, { newline = "\r\n" }) == '[\r\n  1,\r\n  2\r\n]' )
end)


test("encode pretty stable keys", function()
  local t = { banana = 1, apple = 2, cherry = 3, date = 4 }
  -- Keys are emitted in sorted order regardless of table hash ordering
  assert( json.encode(t, true)
    == '{\n  "apple": 2,\n  "banana": 1,\n  "cherry": 3,\n  "date": 4\n}' )
  -- Encoding the same data twice yields byte-identical output
  assert( json.encode(t, true) == json.encode(t, true) )
end)


test("encode pretty preserves errors", function()
  -- Invalid tables must still raise, just like the compact encoder
  local invalid = {
    { x = 10, [1] = 2 },
    { [1] = "a", [3] = "b" },
    { [ function() end ] = 12 },
  }
  for i, v in ipairs(invalid) do
    local status = pcall(json.encode, v, true)
    assert( not status, fmt("pretty encoding idx %d did not error", i) )
  end
  -- Circular references must still be detected
  local a = {}
  a.self = a
  assert( not pcall(json.encode, a, true), "circular reference not detected" )
  -- Invalid numbers still raise
  assert( not pcall(json.encode, math.huge, true) )
end)


test("encode pretty invalid options", function()
  assert( not pcall(json.encode, { a = 1 }, "nope") )
  assert( not pcall(json.encode, { a = 1 }, 5) )
  assert( not pcall(json.encode, { a = 1 }, { indent = -1 }) )
  assert( not pcall(json.encode, { a = 1 }, { indent = 1.5 }) )
  assert( not pcall(json.encode, { a = 1 }, { indent = true }) )
  assert( not pcall(json.encode, { a = 1 }, { newline = 5 }) )
end)
