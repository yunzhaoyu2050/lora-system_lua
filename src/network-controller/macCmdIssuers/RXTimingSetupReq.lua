-- const { utils, consts } = require('../lora-lib');
-- const BluebirdPromise = require('bluebird');
-- const RXTIMESETUPREQ_PARAM = consts.RXTIMINGSETUPREQ;

-- module.exports = function (devAddr, settings) {
--   let _this = this;

--   return new BluebirdPromise((resolve, reject) => {

--     let Settings = Buffer.from([settings], 'hex');
--     if (Settings.length !== RXTIMESETUPREQ_PARAM.SETTINGS_LEN) {
--       reject(new Error(`length of Settings in RXTimingsSetupReq should be ${RXTIMESETUPREQ_PARAM.SETTINGS_LEN}`));
--     }

--     let outputObj = {
--       [Buffer.from([consts.RXTIMINGSETUP_CID], 'hex').toString('hex')]: {
--         Settings: Settings,
--       },
--     };

--     // push cmd req into queue
--     const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
--     _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

--       _this.log.debug({
--         label: 'MAC Command Req',
--         message: {
--           RXTimingSetupReq: mqKey,
--           payload: outputObj,
--         },
--       });

--       resolve(outputObj);
--     });
--   });
-- }