'use strict';

class MacCommand {
  constructor (devAddr, cmd, remains) {
    this.devAddr = devAddr;
    this.macCmd = cmd;
    this.remains = remains;
  }

  getDevAddr () {
    return this.devAddr;
  }

  getMacCmd () {
    return this.macCmd;
  }

  getTx () {
    if (this.remains.hasOwnProperty('devtx')) {
      return this.remains.devtx;
    }

    return null;
  }

  getRx () {
    if (this.remains.hasOwnProperty('gwrx')) {
      return this.remains.gwrx;
    }

    return null;
  }

}

module.exports = MacCommand;
