const BluebirdPromise = require('bluebird');
const { utils, consts } = require('../lora-lib');
const RXPARAMSETUPANS_PARAM = consts.RXPARAMSETUPANS;

module.exports = function (devAddr, status) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Ans',
      message: {
        RXParamSetupAns: {
          Status: status,
        },
      },
    });

    for (let key in status) {
      let Status = Buffer.from(status[key]);
      let RX1DRoffsetACK = utils.bitwiseFilter(Status, RXPARAMSETUPANS_PARAM.RX1DROFFSETACK_START, RXPARAMSETUPANS_PARAM.RX1DROFFSETACK_LEN);
      let RX2DataRateACK = utils.bitwiseFilter(Status, RXPARAMSETUPANS_PARAM.RX2DATARATEACK_START, RXPARAMSETUPANS_PARAM.RX2DATARATEACK_LEN);
      let ChannelACK = utils.bitwiseFilter(Status, RXPARAMSETUPANS_PARAM.CHANNELACK_START, RXPARAMSETUPANS_PARAM.CHANNELACK_LEN);

      if (RX1DRoffsetACK == 1) {
        _this.log.debug({
          label: 'MAC Command Ans',
          message: {
            RXParamSetupAns: {
              RX1DRoffsetACK: 'RX1DRoffset set Success'
            },
          }
        })
      }

      if (RX2DataRateACK == 1) {
        _this.log.debug({
          label: 'MAC Command Ans',
          message: {
            RXParamSetupAns: {
              RX2DataRateACK: 'RX2DataRate set Success'
            }
          }
        })
      }

      if (ChannelACK == 1) {
        _this.log.debug({
          label: 'MAC Command Ans',
          message: {
            RXParamSetupAns: {
              ChannelACK: 'Channel set Success'
            }
          }
        })
      }
    }
    resolve();
  });
};
