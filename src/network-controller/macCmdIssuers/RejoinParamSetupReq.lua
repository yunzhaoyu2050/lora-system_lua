-- const { utils, consts } = require('../lora-lib');
-- const BluebirdPromise = require('bluebird');
-- const REJOINPARAMSETUPREQ_PARAM = consts.REJOINPARAMSETUPREQ;

-- module.exports = function (devAddr, MaxTimeN, MaxCountN) {
--   let _this = this;

--   return new BluebirdPromise((resolve, reject) => {

--     let RejoinParamSetupReq = MaxTimeN * REJOINPARAMSETUPREQ_PARAM.MAXTIMEN_BASE + MaxCountN * REJOINPARAMSETUPREQ_PARAM.MAXCOUNTN_BASE;
--     let RejoinParamSetup = RejoinParamSetupReq.toString(16);
--     if (RejoinParamSetup.length !== (consts.REJOINPARAMSETUPREQ_LEN) * 2) {
--       reject(new Error(`length of RejoinParamSetup in RejoinParamReq should be ${consts.REJOINPARAMSETUPREQ_LEN}`));
--     }

--     let outputObj = {
--       [Buffer.from([consts.REJOINPARAMSETUP_CID], 'hex').toString('hex')]: {
--         RejoinParamSetupReq: utils.numToHexBuf(RejoinParamSetupReq, consts.REJOINPARAMSETUPREQ_LEN),
--       },
--     };

--     // push cmd req into queue
--     const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
--     _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

--       _this.log.debug({
--         label: 'MAC Command Req',
--         message: {
--           RejoinParamSetupReq: mqKey,
--           payload: outputObj,
--         },
--       });

--       resolve(outputObj);
--     });
--   });
-- }