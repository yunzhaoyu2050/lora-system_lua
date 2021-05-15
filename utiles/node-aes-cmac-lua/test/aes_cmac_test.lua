require("emmy_core").tcpListen("localhost", 9966)
p("debug open, listen: " .. "localhost" .. ",port: " .. 9966)
local uv = require("luv")
uv.sleep(5000)

local utiles = require("../../../utiles/utiles.lua")
local aesCmac = require("../lib/aes-cmac.lua").aesCmac
local buffer = require("buffer").Buffer

-- Simple example.
local key = "k3Men*p/2.3j4abB"
local message = "this|is|a|test|message"
local cmac = aesCmac(key, message)
utiles.printBuf(cmac)
p(utiles.BufferToHexString(cmac))
-- cmac will be: '0125c538f8be7c4eea370f992a4ffdcb'

-- Example with buffers.
local bufferKey = buffer:new(string.len("6b334d656e2a702f322e336a34616242") / 2)
utiles.BufferFromHexString(bufferKey, 1, "6b334d656e2a702f322e336a34616242")
local bufferMessage = buffer:new("this|is|a|test|message")
local options = {returnAsBuffer = true} -- options 当前无作用
cmac = aesCmac(bufferKey, bufferMessage, options)
utiles.printBuf(cmac)
p(utiles.BufferToHexString(cmac))
-- cmac will be a Buffer containing:
-- <01 25 c5 38 f8 be 7c 4e ea 37 0f 99 2a 4f fd cb>

while true do
  uv.sleep(1000)
end
