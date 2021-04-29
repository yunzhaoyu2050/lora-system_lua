-- const { consts, utils } = require('../lora-lib');
-- const cmac = require('node-aes-cmac').aesCmac;
-- const crypto = require('crypto');
-- const reverse = utils.bufferReverse;

-- const _this = new function () {
--   /*
--    * Basic block for encryption and MIC
--    */
--   this.basicVerifyBlock = (requiredFields, classification, direction) => {
--     const block = Buffer.alloc(consts.BLOCK_LEN);
--     block[0] = consts.BLOCK_CLASS[classification];
--     direction.copy(block, consts.BLOCK_DIR_OFFSET);
--     const DevAddr = reverse(requiredFields.DevAddr);
--     DevAddr.copy(block, consts.BLOCK_DEVADDR_OFFSET);
--     let FCnt = reverse(requiredFields.FCnt);
--     FCnt.copy(block, consts.BLOCK_FCNT_OFFSET);
--     return block;
--   };

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
    -- local msg = Buffer.concat([
    --   requiredFields.MHDR,
    --   requiredFields.FHDR,
    -- ]);
    -- if (requiredFields.FPort) {
    --   msg = Buffer.concat([msg, requiredFields.FPort]);
    -- }
    -- if (requiredFields.FRMPayload) {
    --   msg = Buffer.concat([msg, requiredFields.FRMPayload]);
    -- }

    -- //Build B0
    -- const block = this.basicVerifyBlock(requiredFields, 'B', direction);

    -- block[consts.BLOCK_LENMSG_OFFSET] = msg.length;
    -- const cmacBlock = Buffer.concat([block, msg], consts.BLOCK_LEN + msg.length);
    -- console.log(cmacBlock);
    -- const options = { returnAsBuffer: true };
    -- return cmac(
    --   key,
    --   cmacBlock,
    --   options
    -- ).slice(0, consts.V102_CMAC_LEN);
  end

-- };

-- module.exports = _this;
return {
  micCalculator = micCalculator
}
