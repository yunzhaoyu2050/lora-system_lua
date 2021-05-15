const { utils, consts } = require('../lora-lib');
const BluebirdPromise = require('bluebird');
const DUTYCYCLEREQ_PARAM = consts.DUTYCYCLEREQ;

module.exports = function (devAddr, MaxDCycle) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {

    if (typeof (MaxDCycle) !== 'number') {
      reject(new Error(`type of MaxDCycle in DutyCycleReq should be number`));
    }

    let DutyCyclePL = MaxDCycle * DUTYCYCLEREQ_PARAM.MAXCYCLE_BASE;
    let DutyCycleLenth = Buffer.from([DutyCyclePL], 'hex');
    if (DutyCycleLenth.length !== DUTYCYCLEREQ_PARAM.DUTYCYCLEPL_LEN) {
      reject(new Error(`length of DutyCyclePayload in DutyCycleReq should be ${DUTYCYCLEREQ_PARAM.DUTYCYCLEPL_LEN}`));
    }

    let outputObj = {
      [Buffer.from([consts.DUTYCYCLE_CID], 'hex').toString('hex')]: {
        DutyCyclePL: utils.numToHexBuf(DutyCyclePL, DUTYCYCLEREQ_PARAM.DUTYCYCLEPL_LEN),
      },
    };

    // push cmd req into queue
    const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
    _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

      _this.log.debug({
        label: 'MAC Command Req',
        message: {
          DutyCycleReq: mqKey,
          payload: outputObj,
        },
      });

      resolve(outputObj);
    });
  });
}