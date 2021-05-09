local utiles = require("../../utiles/utiles.lua")
local buffer = require("buffer").Buffer
local consts = require("../lora-lib/constants/constants.lua")
local aesCmac = require("../../deps/node-aes-cmac-lua/lib/aes-cmac.lua").aesCmac
-- const { consts, utils } = require('../lora-lib');
-- const cmac = require('node-aes-cmac').aesCmac;
-- const crypto = require('crypto');
-- const reverse = utils.bufferReverse;

-- const _this = new function () {
--   /*
--    * Basic block for encryption and MIC
--    */
local function basicVerifyBlock(requiredFields, classification, direction)
  local block = buffer:new(consts.BLOCK_LEN)
  utiles.BufferFill(block, 0, 1, block.length)
  block[1] = consts.BLOCK_CLASS[classification]
  -- direction.copy(block, consts.BLOCK_DIR_OFFSET);
  utiles.BufferCopy(block, consts.BLOCK_DIR_OFFSET + 1, direction, 1, direction.length)
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

--   /*
--    * Server only need to implement AES decryption 服务器只需要实现AES解密
--    */
--   this.decrypt = (requiredFields, key, direction) => {
--     const classification = 'A';
--     const k = Math.ceil(requiredFields.FRMPayload.length / consts.BLOCK_LEN);
--     const fillNum = consts.BLOCK_LEN - requiredFields.FRMPayload.length % consts.BLOCK_LEN;
--     const block = this.basicVerifyBlock(requiredFields, classification, direction);
--     const cipher = crypto.createCipheriv(consts.ENCRYPTION_ALGO, key, '');
--     let S = Buffer.alloc(0);
--     for (let ind = 1; ind <= k; ind++) {
--       let Ai = Buffer.from(block);
--       Ai[consts.BLOCK_LENMSG_OFFSET] = ind;
--       let Si = cipher.update(Ai, 'binary');
--       S = Buffer.concat([S, Si]);
--     }

--     const pld = Buffer.concat([requiredFields.FRMPayload, Buffer.alloc(fillNum)], k * consts.BLOCK_LEN);
--     return (utils.bufferXor(pld, S)).slice(0, requiredFields.FRMPayload.length);
--   };

-- mic 计算
-- requiredFields
--  .MHDR
--  .FHDR
--  .DevAddr
--  .FCnt
--  .FPort
--  .FRMPayload
-- key -> NwkSKey
function micCalculator(requiredFields, key, direction)
  local msg = utiles.BufferConcat(requiredFields.MHDR, requiredFields.FHDR)
  if (requiredFields.FPort) then
    msg = utiles.BufferConcat(msg, requiredFields.FPort)
  end
  if (requiredFields.FRMPayload) then
    msg = utiles.BufferConcat(msg, requiredFields.FRMPayload)
  end
  -- Build B0
  local block = basicVerifyBlock(requiredFields, "B", direction)
  p("   B0:", utiles.BufferToHexString(block))
  block[consts.BLOCK_LENMSG_OFFSET + 1] = msg.length
  p("   block:", utiles.BufferToHexString(block))
  local cmacBlock = utiles.BufferConcat(block, msg, consts.BLOCK_LEN + msg.length)
  -- console.log(cmacBlock);
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
  micCalculator = micCalculator
}
