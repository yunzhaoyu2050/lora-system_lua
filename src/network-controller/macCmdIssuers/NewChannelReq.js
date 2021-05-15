const { utils, consts } = require('../lora-lib');
const BluebirdPromise = require('bluebird');
const NEWCHANELREQ_PARAM = consts.NEWCHANNELREQ;

module.exports = function (devAddr, chindex, freq, maxDR, minDR) {
  let _this = this;

  return new BluebirdPromise((resolve, reject) => {

    let Chindex = Buffer.from([chindex], 'hex');
    if (Chindex.length !== NEWCHANELREQ_PARAM.CHINDEX_LEN) {
      reject(new Error(`length of ChIndex in NewChanelReq should be ${NEWCHANELREQ_PARAM.CHINDEX_LEN}`));
    }

    let Freq = utils.numToHexBuf(freq, NEWCHANELREQ_PARAM.FREQ_LEN);
    if (Freq.length !== NEWCHANELREQ_PARAM.FREQ_LEN) {
      reject(new Error(`length of Freq in NewChanelReq should be ${NEWCHANELREQ_PARAM.FREQ_LEN}`));
    }

    let DrRange = maxDR * NEWCHANELREQ_PARAM.MAXDR_BASE + minDR * NEWCHANELREQ_PARAM.MINDR_BASE;
    let outputObj = {
      [Buffer.from([consts.NEWCHANNEL_CID], 'hex').toString('hex')]: {
        ChIndex: Chindex,
        Freq: Freq,
        DrRange: utils.numToHexBuf(DrRange, NEWCHANELREQ_PARAM.DRRANGE_LEN),
      },
    };

    // push cmd req into queue
    const mqKey = consts.MACCMDQUEREQ_PREFIX + devAddr;
    _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj).then(() => {

      _this.log.debug({
        label: 'MAC Command Req',
        message: {
          NewChanelReq: mqKey,
          payload: outputObj,
        },
      });

      resolve(outputObj);
    });
  });
}