


-- -- require('mobdebug').start("127.0.0.1")
-- function func()
--     local mhdr, mhdrJSON, macPayload, mic = 52, {"HJJKL", 96}, "asdas", 352
--     return {mhdr, mhdrJSON, macPayload, mic}
-- end

-- local uhj = func()
-- p(uhj)

-- local test = {
--     DevEUI = 234,
--     DevAddr = 23423423,
--     AppKey = 'info.AppKey',
--     AppEUI = 'AppEUI',
--     DevNonce = 'DevNonce',
--     AppNonce = 'AppNonce',
--     NwkSKey = 'NwkSKey',
--     AppSKey = 'AppSKey',
--     activationMode = 'activationMode',
--     ProtocolVersion = 'ProtocolVersion',
--     FCntUp = 'FCntUp',
--     NFCntDown = 'NFCntDown',
--     AFCntDown = 'AFCntDown'
-- }
-- local devInfo = {
--     [256] = {},
--     [524] = {}
-- };
-- for k, v in pairs(test) do
--     -- p('k=' .. k)
--     -- p('v=' .. v)

--     devInfo[256][k] = v
--     devInfo[524][k] = v
--     if devInfo[654] == nil then
--         devInfo[654] = {}
--         devInfo[654][k] = v
--         print("error")
--     end
-- end
-- p(devInfo)
-- p(devInfo)

-- -- -- dofile 'luvit-loader.lua'
-- -- print(require('luv')) -- Require luv directly using package.cpath
-- -- print(require('uv')) -- Require luv indirectly using deps/uv.lua shim

local buffer = require("buffer").Buffer
-- local num = {
--     mdf = 12,
--     jhs = 312312
-- }
-- local buf = Buffer:new(tostring(num))
-- p(buf:readUInt8())

local data = {
    ["asdfg123asad"] = {
        mn = 20,
        as = "sad"
    },
    ["asdas12sdsa45"] = {
        mn = 23,
        as = "asdqw"
    }
}

-- for k,v in pairs(data) do
--     p(k) p(v)
--     for i,j in pairs(data[k]) do
--         p(i) p(j)
--         if i == 'mn' then
--             -- if 
--         end
--     end
-- end


-- local tmp = bit.bxor(60, 13)
-- p(tmp)

-- -- local out = tmp == 49?1:0

-- local M = {}
-- for i=1,5,1 do -- memset(M[0], 0x00, (*n) * 16)
--     M[i]={}
--     for j=1,16,1 do
--         M[i][j]=0x00
--     end
-- end

-- p(M)

-- package.cpath="/home/ubuntu/lora/luvit-app-x86_64-test/lora-system_lua/deps/crypto_project/?.so;"
-- require('emmy_core').tcpListen('localhost', 9966)
-- p('debug open, listen: ' .. 'localhost' .. ',port: ' .. 9966)

-- p(package.cpath)
-- local ffi = require("ffi")
-- local aes = ffi.load("/home/ubuntu/lora/luvit-app-x86_64-test/lora-system_lua/deps/crypto_project/libaes.so")
-- ffi.cdef[[
--     void aes_cmac(uint8_t *input, unsigned long length, uint8_t *key, uint8_t *mac_value)
-- ]]

-- function copyArr(dst,src)
--     for i=1,src.length,1 do
--         dst[i-1]=src[i]
--     end
-- end

-- function clearArr(dst,len)
--     for i=0,len-1,1 do
--         dst[i-1]=src[i]
--     end
-- end

-- function copyStr(dst,src)
--     for i=1,#src,1 do
--         dst[i]=string.byte(src,i)
--     end
-- end

-- function printArr(m, len)
--     for i=1,len,1 do
--         p("i: "..i..",v: "..m[i])
--     end
-- end


-- function printArr2(m, len)
--     for i=0,len-1,1 do
--         p("i: "..i..",v: "..m[i])
--     end
-- end

-- function cmac(inMsg, inKey)
--     local bufMsg = buffer:new(#inMsg)
--     copyStr(bufMsg, inMsg)
--     local input = ffi.new("uint8_t[?]", #inMsg)
--     copyArr(input, bufMsg)
--     local bufKey = buffer:new(#inKey+1)
--     copyStr(bufKey, inKey) bufKey[#inKey+1]=0
--     local key = ffi.new("uint8_t[?]", #inKey+1)
--     copyArr(key, bufKey)
--     local tmp = ffi.new("uint8_t[?]", 16)
--     aes.aes_cmac(input, #inMsg, key, tmp)
--     local output=utiles.BufferToHexString(tmp, 0, 15)
--     return output
--     -- p(utiles.BufferToHexString(tmp, 0, 15)) -- test
-- end

-- local inputMsg="asdasdsadasdqwdwqdqwdwqdjwindwncwnc,dwdwd.wdwqdqwdqw23e23e23j230n3920ne302he230h302324239ui90x0as"

-- -- local inputMsg="qwery"

-- -- local inputKey="12345"
-- local inputKey="secretkey2132131"
-- cmac(inputMsg, inputKey)
local utiles = require("../utiles/utiles.lua")

local bb = buffer:new(23)
p(type(bb))
p(bb)
p(data)

crypto = require('../deps/lua-openssl/lib/crypto.lua')


function tohex(s)
	return (s:gsub('.', function (c) return string.format("%02x", string.byte(c)) end))
end
function hexprint(s)
	print(crypto.hex(s))
end
-- TESTING HEX

local tst = 'abcd'
assert(crypto.hex, "missing crypto.hex")
local actual = crypto.hex(tst)
local expected = tohex(tst)
assert(actual == expected, "different hex results")

p(actual)
p(expected)


local const_Rb = '00000000000000000000000000000087'

local buf = buffer:new(const_Rb)
-- utiles.printBuf(buf)


utiles.switch(2) {
    [1] = function () print"number 1!" end,
    [2] = math.sin,
    [false] = function (a) return function (b) return (a or b) and not (a and b) end end,
    Default = function (x) print"Look, Mom, I can differentiate types!" end, -- ["Default"] ;)
    [utiles.Default] = print,
    [utiles.Nil] = function () print"I must've left it in my other jeans." end,
}
function test()
    p(__func__)
end

test()