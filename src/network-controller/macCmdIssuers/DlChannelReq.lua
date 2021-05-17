-- const { utils, consts } = require('../lora-lib');
-- const BluebirdPromise = require('bluebird');
-- const DLCHANNEL_PARAM = consts.DLCHANNELREQ;

-- module.exports = function (devAddr, chIndex, Frequen) {
--     let _this = this;

--     return new BluebirdPromise((resolve, reject) => {
--         if (typeof (chIndex) !== 'number') {
--             reject(new Error(`type of chIndex in DlChannelReq should be number`));
--         }

--         if (typeof (Frequen) !== 'number') {
--             reject(new Error(`type of Frequen in DlChannelReq should be number`));
--         }

--         let outputObj = {
--             [Buffer.from([consts.DLCHANNEL_CID], 'hex').toString('hex')]: {
--                 ChIndex: utils.numToHexBuf(chIndex, DLCHANNEL_PARAM.CHINDEX_LEN),
--                 Freq: utils.numToHexBuf(Frequen, DLCHANNEL_PARAM.FREQ_LEN),
--             },
--         };

--         // push cmd req into queue
--         const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
--         _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj)
--             .then(() => {

--                 _this.log.debug({
--                     label: 'MAC Command Req',
--                     message: {
--                         DlChannelReq: mqKey,
--                         payload: outputObj,
--                     },
--                 });

--                 resolve(outputObj);
--             });
--     });
-- }