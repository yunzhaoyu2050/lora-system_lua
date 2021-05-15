const { utils, consts } = require('../lora-lib');
const BluebirdPromise = require('bluebird');

module.exports = function (devAddr) {
  let _this = this;

  return new BluebirdPromise((resolve, reject) => {

    let outputObj = {
      [Buffer.from([consts.DEVSTATUS_CID], 'hex').toString('hex')]: {
      },
    };

    // push cmd req into queue
    const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
    _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

      _this.log.debug({
        label: 'MAC Command Req',
        message: {
          DevStatusReq: mqKey,
          payload: outputObj,
        },
      });

      resolve(outputObj);
    });
  });
}