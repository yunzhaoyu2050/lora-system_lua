const { utils, consts } = require('../lora-lib');
const BluebirdPromise = require('bluebird');
const RXPARAMSETUPREQ_PARAM = consts.RXPARAMSETUPREQ;

module.exports = function (devAddr, RX1DRoffset, RX2DataRate, frequency) {
  let _this = this;

  return new BluebirdPromise((resolve, reject) => {

    let Frequency = utils.numToHexBuf(frequency, RXPARAMSETUPREQ_PARAM.FREQUENCY_LEN);
    if (Frequency.length !== RXPARAMSETUPREQ_PARAM.FREQUENCY_LEN) {
      reject(new Error(`length of Frequency in RXParamSetupReq should be ${RXPARAMSETUPREQ_PARAM.FREQUENCY_LEN}`));
    }

    let DLSettings = RX1DRoffset * RXPARAMSETUPREQ_PARAM.RX1DROFFSET_BASE +
      RX2DataRate * RXPARAMSETUPREQ_PARAM.RX2DATARATE_BASE;
    let outputObj = {
      [Buffer.from([consts.RXPARAMSETUP_CID], 'hex').toString('hex')]: {
        DLSettings: utils.numToHexBuf(DLSettings, RXPARAMSETUPREQ_PARAM.DLSETTINGS_LEN),
        Frequency: Frequency,
      },
    };

    // push cmd req into queue
    const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
    _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

      _this.log.debug({
        label: 'MAC Command Req',
        message: {
          RXParamSetupReq: mqKey,
          payload: outputObj,
        },
      });

      resolve(outputObj);
    });
  });
}