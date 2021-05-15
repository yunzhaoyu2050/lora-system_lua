const BluebirdPromise = require('bluebird');
const { utils, consts } = require('../lora-lib');
const REJOINPARAMSETUPANS_PARAM = consts.REJOINPARAMSETUPANS;

module.exports = function (devAddr, status) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Ans',
      message: {
        RejoinParamSetupAns: {
          Status: status,
        },
      },
    });

    let key_in = new Array();
    for (let key in status) {
      key_in.push(key);
    }
    let Status = Buffer.from(status[key_in[0]]);
    let TimeOK = utils.bitwiseFilter(Status, REJOINPARAMSETUPANS_PARAM.TIMEOK_START, REJOINPARAMSETUPANS_PARAM.TIMEOK_LEN);

    if (TimeOK === 1) {
      _this.log.debug({
        label: 'MAC Command Ans',
        message: {
          RejoinParamSetupAns: {
            TimeOK: 'The device accepted the time and quantity limit',
          }
        }
      })
    }

    resolve();
  });
};
