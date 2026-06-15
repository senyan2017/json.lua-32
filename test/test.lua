
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
  -- Handle json.null sentinel
  if a == json.null and b == json.null then return true end
  if a == json.null or b == json.null then return false end
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
  assert( json.decode("null") == json.null )
  assert( json.encode(nil) == "null")
  assert( json.encode(json.null) == "null")
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


test("null round trip - array", function()
  local src = '[1,null,3]'
  local decoded = json.decode(src)
  -- Length must be preserved (middle null must not collapse the array)
  assert( #decoded == 3, fmt("expected length 3, got %d", #decoded) )
  assert( decoded[1] == 1 )
  assert( decoded[2] == json.null )
  assert( decoded[3] == 3 )
  -- Re-encode must produce the original JSON
  local re = json.encode(decoded)
  assert( re == src, fmt("expected '%s', got '%s'", src, re) )
end)


test("null round trip - object", function()
  local src = '{"a":1,"b":null,"c":"x"}'
  local decoded = json.decode(src)
  assert( decoded.a == 1 )
  assert( decoded.b == json.null )
  assert( decoded.c == "x" )
  -- The key "b" must still exist
  assert( decoded["b"] ~= nil, "null field 'b' was lost" )
  -- Round-trip: decode then encode
  local re = json.encode(decoded)
  local decoded2 = json.decode(re)
  assert( equal(decoded, decoded2), "object round trip mismatch" )
end)


test("null round trip - nested", function()
  local src = '{"x":[1,null,{"y":null}],"z":null}'
  local decoded = json.decode(src)
  assert( decoded.x[1] == 1 )
  assert( decoded.x[2] == json.null )
  assert( decoded.x[3].y == json.null )
  assert( decoded.z == json.null )
  local re = json.encode(decoded)
  local decoded2 = json.decode(re)
  assert( equal(decoded, decoded2), "nested round trip mismatch" )
end)


test("null in all positions", function()
  -- null at head, middle and tail of an array
  local src = '[null,1,null,2,null]'
  local decoded = json.decode(src)
  assert( #decoded == 5, fmt("expected length 5, got %d", #decoded) )
  assert( decoded[1] == json.null )
  assert( decoded[2] == 1 )
  assert( decoded[3] == json.null )
  assert( decoded[4] == 2 )
  assert( decoded[5] == json.null )
  local re = json.encode(decoded)
  assert( re == src, fmt("expected '%s', got '%s'", src, re) )
end)


test("null is not nil", function()
  -- json.null and Lua nil must be distinguishable
  assert( json.null ~= nil, "json.null must not equal Lua nil" )
  assert( type(json.null) == "table", "json.null must be a table sentinel" )
end)
