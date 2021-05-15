const BluebirdPromise = require('bluebird');
const { utils, consts } = require('../lora-lib');
const DEVSTATUSANS_PARAM = consts.DEVSTATUSANS;

module.exports = function (devAddr, status) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Ans',
      message: {
        DevStatusAns: {
          Status: status,
        },
      },
    });

    let key_in = new Array();
    for (let key in status) {
      key_in.push(key);
    }
    let battery = Buffer.from(status[key_in[0]]);
    let margin = Buffer.from(status[key_in[1]]);
    let Battery = utils.bitwiseFilter(battery, 0, 7); //change buffer to num
    let Margin = utils.bitwiseFilter(margin, 0, 5); //change buffer to num

    if (Battery === 0) {
      _this.log.debug({
        label: 'MAC Command Ans',
        message: {
          DevStatusAns: {
            Battery: 'Device had connect to extra battery',
            Margin: 'Margin is ' + Margin,
          }
        }
      })
    }

    if (Battery === 255) {
      _this.log.debug({
        label: 'MAC Command Ans',
        message: {
          DevStatusAns: {
            Battery: 'Device can not measure the battery',
            Margin: 'Margin is ' + Margin,
          }
        }
      })
    }

    resolve();
  });
};
