const { utils, consts } = require('../lora-lib');
const BluebirdPromise = require('bluebird');
const FORCEREJOINREQ_PARAM = consts.FORCEREJOINREQ;

module.exports = function (devAddr, Period, Max_Retries, RejoinType, DR) {
  let _this = this;

  return new BluebirdPromise((resolve, reject) => {

    let ForceRejoinREQ = Period * FORCEREJOINREQ_PARAM.PERIOD_BASE + Max_Retries * FORCEREJOINREQ_PARAM.MAX_RETRIES_BASE +
      RejoinType * FORCEREJOINREQ_PARAM.REJOINTYPE_BASE + DR * FORCEREJOINREQ_PARAM.DR_BASE;
    let ForceRejoin = ForceRejoinREQ.toString(16);
    if (ForceRejoin.length !== (consts.FORCEREJOINREQ_LEN) * 2) {
      reject(new Error(`length of ForceRejoinReq in ForceRejoinReq should be ${consts.FORCEREJOINREQ_LEN}`));
    }

    let outputObj = {
      [Buffer.from([consts.FORCEREJOIN_CID], 'hex').toString('hex')]: {
        ForcerRejoinReq: utils.numToHexBuf(ForceRejoinREQ, consts.FORCEREJOINREQ_LEN),
      },
    };

    // push cmd req into queue
    const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
    _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

      _this.log.debug({
        label: 'MAC Command Req',
        message: {
          ForceRejoinReq: mqKey,
          payload: outputObj,
        },
      });

      resolve(outputObj);
    });
  });
}