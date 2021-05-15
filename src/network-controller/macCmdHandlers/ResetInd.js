const BluebirdPromise = require('bluebird');
const { consts, utils } = require('../lora-lib');
const RESTIND_PARAM = consts.RESETIND;
const MacCommandIssuers = require('../macCmdIssuers');

module.exports = function (devAddr, status) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Ans',
      message: {
        ResetInd: {
          Status: status,
        },
      },
    });

    for (let key in status) {
      let version = status[key];
      let Status = Buffer.from(version);
      let Minor = utils.bitwiseFilter(Status, RESTIND_PARAM.MINOR_START, RESTIND_PARAM.MINOR_LEN);

      if (Minor === 1) {
        _this.log.debug({
          label: 'MAC Command Ans',
          message: {
            ResetInd: {
              Minor: 'Minor=1 set Success',
            }
          }
        })
      }

      let MacCommandIssuer = MacCommandIssuers[consts.RESET_CID].bind(_this, devAddr, Minor);
      return MacCommandIssuer();
    }

    resolve();
  });
};
