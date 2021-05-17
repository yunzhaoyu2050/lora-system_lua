-- const { utils, consts } = require('../lora-lib');
-- const BluebirdPromise = require('bluebird');

-- module.exports = function (devAddr, version) {
--   let _this = this;
--   return new BluebirdPromise((resolve, reject) => {

--     let outputObj = {
--       [Buffer.from([consts.RESET_CID], 'hex').toString('hex')]: {
--         Version: utils.numToHexBuf(version, consts.RESETCONF_LEN),
--       },
--     };

--     // push cmd req into queue
--     const mqKey = consts.MACCMDQUEANS_PREFIX + devAddr;
--     _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

--       _this.log.debug({
--         label: 'MAC Command Ans',
--         message: {
--           ResetConf: mqKey,
--           payload: outputObj,
--         },
--       });

--       resolve(outputObj);
--     });
--   });
-- }