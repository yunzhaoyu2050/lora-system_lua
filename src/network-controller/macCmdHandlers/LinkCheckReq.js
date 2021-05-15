const utils = require('../lora-lib/utils');
const BluebirdPromise = require('bluebird');
const constants = require('../lora-lib/constants');

module.exports = function (devAddr, devtx, gwrx) {

  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Req',
      message: {
        LinkCheckReq: {
          devAddr: devAddr,
          devtx: devtx,
          gwrx: gwrx,
        },
      },
    });

    let sf = devtx.datr.substring('SF'.length, devtx.datr.indexOf('BW'));
    let requireSNR = constants.SF_REQUIREDSNR[sf];
    let maxLSNR = constants.SF_REQUIREDSNR[sf];
    gwrx.forEach((element, index) => {
      if (element.lsnr > maxLSNR) {
        maxLSNR = element.lsnr;
      }
    });

    if (!requireSNR) {
      reject(new Error(`sf ${devtx.datr} not in sf to required snr table`));
    }

    let Margin = maxLSNR - requireSNR;
    if (Margin < 0) {
      Margin = 0;
    }

    let outputObj = {
      [Buffer.from([constants.LINKCHECK_CID], 'hex').toString('hex')]: {
        Margin: utils.numToHexBuf(Math.round(Margin), constants.LINKCHECKANS.MARGIN_LEN),
        GwCnt: utils.numToHexBuf(gwrx.length, constants.LINKCHECKANS.GWCNT_LEN),
      },
    };

    // push cmd ans into queue
    const mqKey = constants.MACCMDQUEANS_PREFIX + devAddr;
    _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {
      _this.log.debug({
        label: 'MAC Command Ans',
        message: {
          LinkCheckAns: mqKey,
          payload: outputObj,
        },
      });

      resolve();
    });
  });

};
