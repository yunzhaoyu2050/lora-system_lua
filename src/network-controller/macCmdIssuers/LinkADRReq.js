const utils = require('../lora-lib/utils');
const BluebirdPromise = require('bluebird');
const constants = require('../lora-lib/constants');
const LINKADRREQ_PARAM = constants.LINKADRREQ;

module.exports = function (devAddr, dr, tx, chmask, ChMaskCntl, NbTrans) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {

    let ChMask = chmask.toString(16);
    if (ChMask.length !== ((LINKADRREQ_PARAM.CHMASK_LEN) * 2)) {
      reject(new Error(`length of ChMask in LinkADRReq should be ${LINKADRREQ_PARAM.CHMASK_LEN}`));
    }

    let datarateTxpower = dr * LINKADRREQ_PARAM.DATARATE_BASE + tx * LINKADRREQ_PARAM.TXPOWER_BASE;
    let redundancy = ChMaskCntl * LINKADRREQ_PARAM.CHMASKCNTL_BASE +
      NbTrans * LINKADRREQ_PARAM.NBTRANS_BASE;
    let outputObj = {
      [Buffer.from([constants.LINKADR_CID], 'hex').toString('hex')]: {
        TXPower: utils.numToHexBuf(datarateTxpower, LINKADRREQ_PARAM.DATARATE_TXPOWER_LEN),
        ChMask: utils.numToHexBuf(chmask, LINKADRREQ_PARAM.CHMASK_LEN),
        Redundancy: utils.numToHexBuf(redundancy, LINKADRREQ_PARAM.REDUNDANCY_LEN),
      },
    };

    // push cmd req into queue
    const mqKey = constants.MACCMDQUEREQ_PREFIX + devAddr;
    _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

      _this.log.debug({
        label: 'MAC Command Req',
        message: {
          LinkADRReq: mqKey,
          payload: outputObj,
        },
      });

      resolve(outputObj);
    });
  });
};
