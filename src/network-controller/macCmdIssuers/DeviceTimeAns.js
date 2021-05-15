const { utils, consts } = require('../lora-lib');
const BluebirdPromise = require('bluebird');
const DEVICETIMEANS_PARAM = consts.DEVICETIMEANS;

module.exports = function (devAddr, seconds, fractionalsec) {
    let _this = this;

    return new BluebirdPromise((resolve, reject) => {
        if (typeof (seconds) !== 'number') {
            reject(new Error(`type of Seconds in DeviceTimeAns should be number`));
        }

        if (typeof (fractionalsec) !== 'number') {
            reject(new Error(`type of FractionalSec in DeviceTimeAns should be number`));
        }

        let Seconds = utils.numToHexBuf(seconds, DEVICETIMEANS_PARAM.SECONDS_LEN);
        if (Seconds.length !== DEVICETIMEANS_PARAM.SECONDS_LEN) {
            reject(new Error(`length of Seconds in DeviceTimeAns should be ${DEVICETIMEANS_PARAM.SECONDS_LEN}`));
        }

        let FractionalSec = utils.numToHexBuf(fractionalsec, DEVICETIMEANS_PARAM.FRACTIONALSEC_LEN);
        if (FractionalSec.length !== DEVICETIMEANS_PARAM.FRACTIONALSEC_LEN) {
            reject(new Error(`length of FractionalSec in DeviceTimeAns should be ${DEVICETIMEANS_PARAM.FRACTIONALSEC_LEN}`));
        }

        let outputObj = {
            [Buffer.from([consts.DEVICETIME_CID], 'hex').toString('hex')]: {
                Seconds: Seconds,
                FractionalSec: FractionalSec,
            },
        };

        // push cmd req into queue
        const mqKey = consts.MACCMDQUEANS_PREFIX + devAddr;
        _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj)
            .then(() => {

                _this.log.debug({
                    label: 'MAC Command Ans',
                    message: {
                        DeviceTimeAns: mqKey,
                        payload: outputObj,
                    },
                });

                resolve(outputObj);
            });
    });
}