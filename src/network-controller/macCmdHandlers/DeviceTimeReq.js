const BluebirdPromise = require('bluebird');
const { consts, utils } = require('../lora-lib');
const MacCommandIssuers = require('../macCmdIssuers');

module.exports = function (devAddr, status, gwrx) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Ans',
      message: {
        DeviceTimeReq: {
          Status: status,
        },
      },
    });

    let time = Date.now() / 1000;
    let seconds = parseInt(time);
    let fractional_time = time - parseInt(time);
    let fractionalsec = parseInt(fractional_time * 256);
    let MacCommandIssuer = MacCommandIssuers[consts.DEVICETIME_CID].bind(_this, devAddr, seconds, fractionalsec);
    return MacCommandIssuer();

    resolve();
  });
};
