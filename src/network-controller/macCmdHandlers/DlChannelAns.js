const BluebirdPromise = require('bluebird');
const { utils, consts } = require('../lora-lib');
const DLCHANNELANS_PARAM = consts.DLCHANNELANS;

module.exports = function (devAddr, status) {
  let _this = this;
  return new BluebirdPromise((resolve, reject) => {
    _this.log.debug({
      label: 'MAC Command Ans',
      message: {
        DlChannelAns: {
          Status: status,
        },
      },
    });

    let key_in = new Array();
    for (let key in status) {
      key_in.push(key);
    }
    let Status = Buffer.from(status[key_in[0]]);
    let channelFrequency = utils.bitwiseFilter(Status, DLCHANNELANS_PARAM.CHANNELFREQUENCY_START, DLCHANNELANS_PARAM.CHANNELFREQUENCY_LEN);
    let uplinkFrequency = utils.bitwiseFilter(Status, DLCHANNELANS_PARAM.UPLINKFREQUENCY_START, DLCHANNELANS_PARAM.UPLINKFREQUENCY_LEN);

    if (channelFrequency === 1) {
      _this.log.debug({
        label: 'MAC Command Ans',
        message: {
          DlChannelAns: {
            ChannelFrequency: 'Device can use the setted frequency',
          }
        }
      })
    }

    if (uplinkFrequency === 1) {
      _this.log.debug({
        label: 'MAC Command Ans',
        message: {
          DlChannelAns: {
            uplinkFrequency: 'The channel uplink frequency is legal',
          }
        }
      })
    }

    resolve();
  });
};
