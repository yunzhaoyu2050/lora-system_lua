'use strict';

const BluebirdPromise = require('bluebird');
const constants = require('../lora-lib/constants');
const LinkADRReqIssuer = require('../macCmdIssuers/')[constants.LINKADR_CID];

class AdrControlScheme {

  // TODO set timer (mode related) or just once
  // each device can have diff timer
  constructor(mysqlConn, redisConn, log) {

    this.mysqlConn = mysqlConn;
    this.redisConn = redisConn;
    this.log = log;
  }

  adrHandler(devAddr, devtx) {

    let _this = this;

    let DeviceStatus = _this.mysqlConn.DeviceStatus;
    let DeviceConfig = _this.mysqlConn.DeviceConfig;

    let freqPlan;
    let freqPlanOffset;
    let datr = devtx.datr; // get device tx data
    let sf = datr.substring('SF'.length, datr.indexOf('BW'));
    let bandwith = datr.substring(datr.indexOf('BW')); // e.g. 'BW125'

    return DeviceConfig.readItem({ DevAddr: devAddr }, ['frequencyPlan'])
      .then((res) => {
        freqPlan = res.frequencyPlan;
        freqPlanOffset = constants.FREQUENCY_PLAN_LIST.indexOf(freqPlan);

        return DeviceStatus.orderItem(
          { DevAddr: devAddr },
          ['lsnr'],
          ['id', 'DESC'],
          constants.ADR_CONTROLSCHEME_PARAM.LATEST_SNR_NO);
      })
      .then((res) => {
        let linkAdrParam = _this.__baseAdr(freqPlan, sf, res);

        let DataRate = constants.LINKADRREQ.DATARATE_DEFAULT;
        let TXPower = constants.LINKADRREQ.TXPOWER_DEFAULT;

        if (linkAdrParam.hasOwnProperty('DataRate')) {
          let drStr = 'SF' + linkAdrParam.DataRate + bandwith;
          DataRate = constants.DR_PARAM.DRUP[freqPlanOffset][drStr].slice('DR'.length);
        }

        if (linkAdrParam.hasOwnProperty('TXPower')) {
          TXPower = linkAdrParam.TXPower;
        }

        if (!linkAdrParam.hasOwnProperty('DataRate') && !linkAdrParam.hasOwnProperty('TXPower')) {
          _this.log.debug({
            label: 'adr device remains unchanged.',
          });
          return BluebirdPromise.resolve();
        }

        // remain unchanged
        let chmask = constants.ADR_CONTROLSCHEME_PARAM.CHMASK_DEFAULT;
        let ChMaskCntl = constants.ADR_CONTROLSCHEME_PARAM.CHMASKCNTL_DEFAULT[freqPlan];
        let NbTrans = constants.ADR_CONTROLSCHEME_PARAM.NBTRANS_DEFAULT;

        let arguArr = [devAddr, DataRate, TXPower, chmask, ChMaskCntl, NbTrans];
        return LinkADRReqIssuer.apply(_this, arguArr);

      });
  }

  /* Base ADR Algorithm */
  __baseAdr(freqPlan, sf, snrArr) {

    let minSF = constants.SPREADFACTOR_MIN;
    let minTP = constants.TXPOWER_MIN;
    let maxTP = constants.TXPOWER_MAX_LIST[freqPlan];

    let tp = maxTP;

    function getSum(pre, cur) {
      return pre + cur.lsnr;
    }

    let snrAvg = snrArr.reduce(getSum, 0) / snrArr.length;

    let snrReq = constants.SF_REQUIREDSNR[sf];
    let deviceMargin = constants.ADR_CONTROLSCHEME_PARAM.DEVICEMARGIN;
    let snrMargin = snrAvg - snrReq - deviceMargin;

    let steps = Math.floor(snrMargin / constants.ADR_CONTROLSCHEME_PARAM.STEPS_DIVISOR);

    let DataRateKeep = true;
    let TXPowerKeep = true;

    while (steps > 0 && sf > minSF) {
      sf -= constants.ADR_CONTROLSCHEME_PARAM.SF_STEP;
      DataRateKeep = false;
      steps--;
    }

    // devices using 1.1 dont have certain 'tp'
    // devices using 1.0.2 cannot modify 'tp' it self, only be modified by server
    // but we dont keep the 'tp' item in 'DeviceConfig' table
    /*
    while (steps > 0 && tp > minTP) {
      tp -= constants.ADR_CONTROLSCHEME_PARAM.TXPOWER_STEP;
      TXPowerKeep = false;
      steps --;
    }

    if (steps < 0 && tp < maxTP) {
      tp = maxTP;
      TXPowerKeep = false;
    }
    */

    let res = {};
    if (!DataRateKeep) {
      res.DataRate = sf;
    }

    if (!TXPowerKeep) {
      res.TXPower = tp;
    }

    return res;
  }

}

module.exports = AdrControlScheme;
