const { utils, consts } = require('../lora-lib');
const BluebirdPromise = require('bluebird');

module.exports = function (devAddr, version) {
    let _this = this;

    return new BluebirdPromise((resolve, reject) => {

        let Version = Buffer.from([version], 'hex');
        if (Version.length !== consts.REKEYCONF_LEN) {
            reject(new Error(`length of Version in RekeyConf should be ${consts.REKEYCONF_LEN}`));
        }

        let outputObj = {
            [Buffer.from([consts.REKEY_CID], 'hex').toString('hex')]: {
                Version: Version,
            },
        };

        // push cmd req into queue
        const mqKey = consts.MACCMDQUEANS_PREFIX + devAddr;
        _this.redisConn.DownlinkCmdQueue.produce(mqKey, outputObj)
            .then(() => {

                _this.log.debug({
                    label: 'MAC Command Ans',
                    message: {
                        RekeyConf: mqKey,
                        payload: outputObj,
                    },
                });

                resolve(outputObj);
            });
    });
}