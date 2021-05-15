const { utils, consts } = require('../lora-lib');
const BluebirdPromise = require('bluebird');
const ADRPARAMSETUP_PARAM = consts.ADRPARAMSETUPREQ;
// Limit_exp && Delay_exp number
module.exports = function (devAddr, Limit_exp, Delay_exp) {
  let _this = this;

  return new BluebirdPromise((resolve, reject) => {
    if (typeof (Limit_exp) !== 'number') {
      reject(new Error(`type of Limit_exp in ADRParamSetupReq should be number`));
    }

    if (typeof (Delay_exp) !== 'number') {
      reject(new Error(`type of Delay_exp in ADRParamSetupReq should be number`));
    }

    let ADRPARAM = Limit_exp * ADRPARAMSETUP_PARAM.LIMIT_EXP_BASE +
      Delay_exp * ADRPARAMSETUP_PARAM.DELAY_EXP_BASE;
    let outputObj = {
      [Buffer.from([consts.ADRPARAMSETUP_CID], 'hex').toString('hex')]: {
        ADRparam: utils.numToHexBuf(ADRPARAM, ADRPARAMSETUP_PARAM.ADRPARAM_LEN),
      },
    };

    // push cmd req into queue
    const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
    _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj)
      .then(() => {

        _this.log.debug({
          label: 'MAC Command Req',
          message: {
            ADRParamSetupReq: mqKey,
            payload: outputObj,
          },
        });

        resolve(outputObj);
      });
  });
}