const BluebirdPromise = require('bluebird');

module.exports = function (devAddr, status) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Ans',
      message: {
        RXTimingSetupAns: {
          Status: 'The payload is null',
        },
      },
    });

    resolve();
  });
};
