-- Design By https://github.com/allan-stewart/node-aes-cmac.git

local crypto = require("../../../deps/lua-openssl/lib/crypto.lua")
local bufferTools = require("./buffer-tools.lua")
local buffer = require("buffer").Buffer
local utiles = require("../../utiles.lua")

-- local const_Zero = "0000000000000000" --16 bits hex numbers
local hex_Zero = "00000000000000000000000000000000"
local const_Zero = buffer:new(string.len(hex_Zero) / 2)
utiles.BufferFromHexString(const_Zero, 1, hex_Zero)
-- local const_Rb = "000000000000000" -- 16 bits hex numbers
local hex_Rb = "00000000000000000000000000000087"
local const_Rb = buffer:new(string.len(hex_Rb) / 2)
utiles.BufferFromHexString(const_Rb, 1, hex_Rb)
local const_blockSize = 16

-- @param message type:buffer
-- @param blockIndex type:number
local function getMessageBlock(message, blockIndex) -- 规定：一般情况下输入的blockIndex是按照数组从0开始的
  local block = buffer:new(const_blockSize)
  local startIndex = blockIndex * const_blockSize
  local endIndex = startIndex + const_blockSize
  utiles.BufferCopy(block, 1, message, startIndex + 1, endIndex + 1)
  return block
end

-- @param message type: buffer
-- @param blockIndex type: number
local function getPaddedMessageBlock(message, blockIndex) -- 规定：一般情况下输入的blockIndex是按照数组从0开始的
  local block = buffer:new(const_blockSize)
  local startIndex = blockIndex * const_blockSize
  local endIndex = message.length
  utiles.BufferFill(block, 0)
  utiles.BufferCopy(block, 1, message, startIndex + 1, endIndex + 1)
  block[endIndex - startIndex + 1] = 0x80
  return block
end

local function aes(key, message)
  local keyLengthToCipher = {
    [16] = "aes128",
    [24] = "aes192",
    [32] = "aes256"
  }
  if keyLengthToCipher[key.length] == nil then
    p("Keys must be 128, 192, or 256 bits in length.")
    return nil
  end
  local tmpmsg = message:toString()
  local tmpkey = key:toString()
  local res = crypto.encrypt(keyLengthToCipher[key.length], tmpmsg, tmpkey, const_Zero:toString()) -- cbc加密 iv偏移量为固定值
  res = crypto.hex(res)
  local result = buffer:new(string.len(res) / 2)
  utiles.BufferFromHexString(result, 1, res)
  result = utiles.BufferSlice(result, 1, 16)
  return result
end

-- Generate Subkeys
-- @param key type:buffer
local function generateSubkeys(key)
  local l = aes(key, const_Zero)
  local subkey1 = bufferTools.bitShiftLeft(l)
  local t = bit.band(l[1], 0x80)
  if bit.band(l[1], 0x80) ~= 0 then
    subkey1 = bufferTools.xor(subkey1, const_Rb) -- TODO: for debug
  end
  local subkey2 = bufferTools.bitShiftLeft(subkey1)
  if bit.band(subkey1[1], 0x80) ~= 0 then
    subkey2 = bufferTools.xor(subkey2, const_Rb)
  end
  return {
    subkey1 = subkey1,
    subkey2 = subkey2
  }
end

-- cmac 计算
-- @param key type:string or buffer
-- @param message type:string or buffer
function aesCmac(key, message)
  if type(key) == "string" then
    key = buffer:new(key)
  -- elseif key.ctype ~= nil and key.length ~= nil then
  --   p('key is buffer type')
  end
  if type(message) == "string" then
    message = buffer:new(message)
  -- elseif message.ctype ~= nil and message.length ~= nil then
  --   p('message is buffer type')
  end
  -- key message 之后必须为buffer类型
  local subkeys = generateSubkeys(key)
  local messagelen = message.length
  local blockCount = math.ceil(messagelen / const_blockSize)
  local lastBlockCompleteFlag, lastBlock, lastBlockIndex
  if blockCount == 0 then
    blockCount = 1
    lastBlockCompleteFlag = false
  else
    lastBlockCompleteFlag = (messagelen % const_blockSize == 0)
  end
  lastBlockIndex = blockCount - 1
  if lastBlockCompleteFlag then
    lastBlock = bufferTools.xor(getMessageBlock(message, lastBlockIndex), subkeys.subkey1)
  else
    lastBlock = bufferTools.xor(getPaddedMessageBlock(message, lastBlockIndex), subkeys.subkey2)
  end
  local x = buffer:new(string.len(hex_Zero) / 2)
  utiles.BufferFromHexString(x, 1, hex_Zero)
  local y
  for index = 1, lastBlockIndex, 1 do
    y = bufferTools.xor(x, getMessageBlock(message, index - 1))
    x = aes(key, y)
  end
  y = bufferTools.xor(lastBlock, x)
  return aes(key, y)
end

return {
  aesCmac = aesCmac
}
