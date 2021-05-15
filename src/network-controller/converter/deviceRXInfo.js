'use strict';

class DeviceRXInfo {
  constructor(kafkaObject) {
    this.devAddr = kafkaObject.devAddr;
    this.time = kafkaObject.time;
    this.tmms = kafkaObject.tmms;
    this.tmst = kafkaObject.tmst;
    this.freq = kafkaObject.freq;
    this.chan = kafkaObject.chan;
    this.rfch = kafkaObject.rfch;
    this.stat = kafkaObject.stat;
    this.modu = kafkaObject.modu;
    this.datr = kafkaObject.datr;
    this.codr = kafkaObject.codr;
    this.rssi = kafkaObject.rssi;
    this.lsnr = kafkaObject.lsnr;
  }

  getDevAddr() {
    return this.devAddr;
  }

  getDevAddrStr() {
    return this.devAddr.toString('hex');
  }

  getLsnr() {
    return this.lsnr;
  }

  getRssi() {
    return this.rssi;
  }
}

module.exports = DeviceRXInfo;
