const BluebirdPromise = require('bluebird');
const { consts, utils } = require('../lora-lib');
const LINKADRANS_PARAM = consts.LINKADRANS;

module.exports = function (devAddr, status) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Ans',
      message: {
        LinkADRAns: {
          Status: status,
        },
      },
    });

    for (let key in status) {
      let Status = Buffer.from(status[key], 'hex');
      let ChannelMaskACK = utils.bitwiseFilter(Status, LINKADRANS_PARAM.CHANNELMASKACK_START, LINKADRANS_PARAM.CHANNELMASKACK_LEN);
      let DataRateACK = utils.bitwiseFilter(Status, LINKADRANS_PARAM.DATARATEACK_START, LINKADRANS_PARAM.DATARATEACK_LEN);
      let PowerACK = utils.bitwiseFilter(Status, LINKADRANS_PARAM.POWERACK_START, LINKADRANS_PARAM.POWERACK_LEN);

      if (ChannelMaskACK === 1) {
        _this.log.debug({
          label: 'MAC Command Ans',
          message: {
            LinkADRAns: {
              ChannelMaskACK: 'Channel Mask set Success',
            },
          }
        })
      }

      if (DataRateACK === 1) {
        _this.log.debug({
          label: 'MAC Command Ans',
          message: {
            LinkADRAns: {
              DataRateACK: 'Data Rate set Success',
            },
          }
        })
      }

      if (PowerACK === 1) {
        _this.log.debug({
          label: 'MAC Command Ans',
          message: {
            LinkADRAns: {
              PowerACK: 'Power set Success',
            },
          }
        })
      }
    }
    resolve();
  });
};
