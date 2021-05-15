const { utils, consts } = require('../lora-lib');
const BluebirdPromise = require('bluebird');
const TXParamSetupReq_PARAM = consts.TXPARAMSETUPREQ;

module.exports = function (devAddr, DownlinkDwellTime, UplinkDwellTime, MaxEIRP) {
  let _this = this;

  return new BluebirdPromise((resolve, reject) => {

    let MaxDwellTime = DownlinkDwellTime * TXParamSetupReq_PARAM.DOWNLINKDWELLTIME_BASE +
      UplinkDwellTime * TXParamSetupReq_PARAM.UPLINKDWELLTIME_BASE + MaxEIRP * TXParamSetupReq_PARAM.MAXEIRP_BASE;
    let outputObj = {
      [Buffer.from([consts.TXPARAMSETUP_CID], 'hex').toString('hex')]: {
        DwellTime: utils.numToHexBuf(MaxDwellTime, TXParamSetupReq_PARAM.EIRP_DWELLTIME_LEN),
      },
    };

    // push cmd req into queue
    const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
    _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

      _this.log.debug({
        label: 'MAC Command Req',
        message: {
          TXParamSetupReq: mqKey,
          payload: outputObj,
        },
      });

      resolve(outputObj);
    });
  });
}