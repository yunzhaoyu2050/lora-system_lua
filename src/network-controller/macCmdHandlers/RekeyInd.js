const BluebirdPromise = require('bluebird');
const { consts, utils } = require('../lora-lib');
const REKEYIND_PARAM = consts.REKEYIND;
const MacCommandIssuers = require('../macCmdIssuers');

module.exports = function (devAddr, status) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Ans',
      message: {
        RekeyInd: {
          Status: status,
        },
      },
    });

    let key_in = new Array();
    for (let key in status) {
      key_in.push(key);
    }
    let Status = Buffer.from(status[key_in[0]]);
    const minor = utils.bitwiseFilter(Status, REKEYIND_PARAM.MINOR_START, REKEYIND_PARAM.MINOR_LEN);
    if (minor === 1) {
      _this.log.debug({
        label: 'MAC Command Ans',
        message: {
          RekeyInd: {
            Minor: 'Minor=1 set Success',
          }
        }
      })
    }

    let MacCommandIssuer = MacCommandIssuers[consts.REKEY_CID].bind(_this, devAddr, minor);
    return MacCommandIssuer();

    resolve();
  });
};
