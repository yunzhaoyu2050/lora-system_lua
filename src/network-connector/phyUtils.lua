local utiles = require("../../utiles/utiles.lua")
local buffer = require("buffer").Buffer
local consts = require("../lora-lib/constants/constants.lua")
local aesCmac = require("../../utiles/node-aes-cmac-lua/lib/aes-cmac.lua").aesCmac
local crypto = require("../../deps/lua-openssl/lib/crypto.lua")

-- Basic block for encryption and MIC
local function basicVerifyBlock(requiredFields, classification, direction)
  local block = buffer:new(consts.BLOCK_LEN)
  utiles.BufferFill(block, 0, 1, block.length)
  block[1] = consts.BLOCK_CLASS[classification]
  -- direction.copy(block, consts.BLOCK_DIR_OFFSET);
  utiles.BufferCopy(block, consts.BLOCK_DIR_OFFSET + 1, direction, 1, direction.length)
  -- requiredFields.DevAddr[1] = 19
  local DevAddr = utiles.reverse(requiredFields.DevAddr) -- reverse(requiredFields.DevAddr);
  -- p("   DevAddr:", utiles.BufferToHexString(DevAddr))
  -- DevAddr.copy(block, consts.BLOCK_DEVADDR_OFFSET);
  utiles.BufferCopy(block, consts.BLOCK_DEVADDR_OFFSET + 1, DevAddr, 1, DevAddr.length)
  -- p("     block:", utiles.BufferToHexString(block))
  local FCnt = utiles.reverse(requiredFields.FCnt) -- reverse(requiredFields.FCnt);
  -- FCnt.copy(block, consts.BLOCK_FCNT_OFFSET);
  utiles.BufferCopy(block, consts.BLOCK_FCNT_OFFSET + 1, FCnt, 1, FCnt.length)
  -- p("   block:", utiles.BufferToHexString(block))
  return block
end

-- Server only need to implement AES decryption 服务器只需要实现AES解密
function decrypt(requiredFields, key, direction)
  p("  requiredFields.FRMPayload:", utiles.BufferToHexString(requiredFields.FRMPayload))
  p("  direction:", utiles.BufferToHexString(direction))

  local newKey = buffer:new(string.len(key)) -- mysql存储的是hex字符串需要转换成dec的buffer
  utiles.BufferFill(newKey, 0, 1, newKey.length)
  if type(key) == "string" then
    newKey = utiles.BufferFromHexString(newKey, 1, key)
  else
    newKey = key
  end
  newKey = utiles.BufferSlice(newKey, 1, 16)

  local classification = "A"
  local k = math.ceil(requiredFields.FRMPayload.length / consts.BLOCK_LEN)
  local fillNum = consts.BLOCK_LEN - requiredFields.FRMPayload.length % consts.BLOCK_LEN
  local block = basicVerifyBlock(requiredFields, classification, direction)

  -- p("   k:", k)
  -- p("   fillNum:", fillNum)
  -- p("   block:", utiles.BufferToHexString(block))
  -- local cipher = crypto.createCipheriv(consts.ENCRYPTION_ALGO, key, '');

  local S = buffer:new(0)
  for ind = 1, k do
    local Ai = buffer:new(block.length)
    Ai = utiles.BufferCopy(Ai, 1, block, 1, block.length)
    Ai[consts.BLOCK_LENMSG_OFFSET + 1] = ind

    local iv = ""
    local cipher, err = crypto.encrypt("aes128", Ai:toString(), newKey:toString(), iv) -- aes-128-ecb iv=""
    if err ~= nil then
      p("function <crypto.encrypt> aes-128-ecb failed,", err)
      return nil
    end

    -- p(" Ai:", utiles.BufferToHexString(Ai), "key:", utiles.BufferToHexString(newKey))
    -- p("   encrypt FRMPayload:", crypto.hex(cipher))

    cipher = crypto.hex(cipher)
    local Si = buffer:new(string.len(cipher) / 2)
    utiles.BufferFromHexString(Si, 1, cipher)

    -- p("   Si 1:", utiles.BufferToHexString(Si))
    -- Si = utiles.BufferSlice(Si, 1, 16)
    -- p("   Si 2:", utiles.BufferToHexString(Si))

    S = utiles.BufferConcat(S, Si)
  end

  local fi = buffer:new(fillNum)
  utiles.BufferFill(fi, 0, 1, fi.length)

  local pld = utiles.BufferConcat(requiredFields.FRMPayload, fi)
  pld = utiles.BufferSlice(pld, 1, k * consts.BLOCK_LEN)
  -- const pld = Buffer.concat([requiredFields.FRMPayload, Buffer.alloc(fillNum)], k * consts.BLOCK_LEN);
  -- return (utils.bufferXor(pld, S)).slice(0, requiredFields.FRMPayload.length);
  -- p(" pld:", utiles.BufferToHexString(pld))
  -- p(" S:", utiles.BufferToHexString(S))
  local out = utiles.BufferXor(pld, S)
  -- p(" out0:", utiles.BufferToHexString(out))
  out = utiles.BufferSlice(out, 1, requiredFields.FRMPayload.length)
  p("   decrypt out:", utiles.BufferToHexString(out))
  return out
end

-- mic 计算
function micCalculator(requiredFields, key, direction)
  local msg = utiles.BufferConcat(requiredFields.MHDR, requiredFields.FHDR)
  if requiredFields.FPort then
    msg = utiles.BufferConcat(msg, requiredFields.FPort)
  end
  if requiredFields.FRMPayload and requiredFields.FRMPayload.length ~= 0 then
    msg = utiles.BufferConcat(msg, requiredFields.FRMPayload)
    p("msg:", utiles.BufferToHexString(msg))
  end
  -- Build B0
  local block = basicVerifyBlock(requiredFields, "B", direction)
  p("   B0:", utiles.BufferToHexString(block))
  block[consts.BLOCK_LENMSG_OFFSET + 1] = msg.length
  p("   block:", utiles.BufferToHexString(block))
  local cmacBlock = utiles.BufferConcat(block, msg, consts.BLOCK_LEN + msg.length)
  p("   cmacBlock:", utiles.BufferToHexString(cmacBlock))
  -- local options = {returnAsBuffer = true}

  local keyLen = 0
  if type(key) == "string" then
    keyLen = string.len(key)
  elseif key.ctype ~= nil and key.length > 0 then
    keyLen = key.length
  end
  local newKey = buffer:new(keyLen) -- mysql存储的是hex字符串需要转换成dec的buffer
  if type(key) == "string" then
    newKey = utiles.BufferFromHexString(newKey, 1, key)
  else
    newKey = key
  end
  newKey = utiles.BufferSlice(newKey, 1, 16)
  p("   newKey:", utiles.BufferToHexString(newKey))
  local aesval = aesCmac(newKey, cmacBlock)
  p("   aesval:", utiles.BufferToHexString(aesval))
  local res = utiles.BufferSlice(aesval, 1, consts.V102_CMAC_LEN)
  return res
end

return {
  decrypt = decrypt,
  micCalculator = micCalculator
}
