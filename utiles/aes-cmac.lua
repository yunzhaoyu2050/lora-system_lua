
local utiles = require("../utiles/utiles.lua")
local buffer = require("buffer").Buffer
local ffi = require("ffi")
local aes = ffi.load("../lora-system_lua/deps/crypto_project/libaes.so")
-- local aes = ffi.load("/home/ubuntu/lora/luvit-app-x86_64-test/lora-system_lua/deps/AES-CMAC/libaes.so")

ffi.cdef[[
    void aes_cmac(uint8_t *input, unsigned long length, uint8_t *key, uint8_t *mac_value)
]]

-- ffi.cdef[[
--     void aes_cmac(uint8_t* in, unsigned long length, uint8_t* key, uint8_t* out)
-- ]]

local function copyArr(dst,src)
    for i=1,src.length,1 do
        dst[i-1]=src[i]
    end
end

local function copyStr(dst,src)
    for i=1,#src,1 do
        dst[i]=string.byte(src,i)
    end
end

function printArr(m, len)
    for i=1,len,1 do
        p("i: "..i..",v: "..m[i])
    end
end

-- function printArr2(m, len)
--     for i=0,len-1,1 do
--         p("i: "..i..",v: "..m[i])
--     end
-- end

-- aes cmac计算
-- @param inMsg 内容 --bug 存在"\"
-- @param inKey key 必须是16位全字符 --bugkey长度少于16字节
-- @return 返回hex的字符串
function cmac(inKey, inMsg)
    local bufMsg = nil
    local input = nil
    if type(inMsg) == 'string' then
        bufMsg = buffer:new(#inMsg)
        copyStr(bufMsg, inMsg)
        input = ffi.new("uint8_t[?]", #inMsg)
        copyArr(input, bufMsg)
    elseif type(inMsg) == 'table' then
        input = ffi.new("uint8_t[?]", inMsg.length)
        copyArr(input, inMsg)
    end
    -- key的输入为一个字符串
    local bufKey = buffer:new(#inKey+1)
    copyStr(bufKey, inKey) bufKey[#inKey+1]=0
    local key = ffi.new("uint8_t[?]", #inKey+1)
    copyArr(key, bufKey)
    local tmp = ffi.new("uint8_t[?]", 16)
    if type(inMsg) == 'string' then
        aes.aes_cmac(input, #inMsg, key, tmp)
    elseif type(inMsg) == 'table' then
        aes.aes_cmac(input, inMsg.length, key, tmp)
    end
    local output = buffer:new(16)
    for i=0,15,1 do output[i+1] = tmp[i] end
    -- p(utiles.BufferToHexString(tmp, 0, 15)) -- test
    p(utiles.BufferToHexString(output, 1, 16)) -- test
    return output
end
-- local inputMsg="asdasdsadasdqwdwqdqwdwqdjwindwncwnc,dwdwd.wdwqdqwdqw23e23e23j230n3920ne302he230h302324239ui90x0as"
-- local inputKey="secretkey2132131"
-- local nbuf = buffer:new(inputMsg)
-- printArr(nbuf, nbuf.length)
-- -- cmac(inputKey, inputMsg)
-- cmac(inputKey, nbuf)
return {
    cmac = cmac
}