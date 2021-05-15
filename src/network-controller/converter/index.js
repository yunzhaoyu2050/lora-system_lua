'use strict';
const MacCommand = require('./MacCommand.js');

class Coverter {
  constructor(log) {
    this.log = log;
  }

  static getUplinkObj(messageType, messageObj) {
    switch (messageType) {
      case 'MacCommand':
        let macCommand = new MacCommand(messageObj);
        return macCommand;
      case '':
        break;
      default:
        return new Error(JSON.stringify({
          CoverterError: 'Invalid Uplink Message Tyep',
          messageType: messageType,
          messageObj: messageObj,
        }));
    }
  }

  static getDownlinkObj(MessageType, messageObj) {
    switch (MessageType) {
      case 'MacCommand':
        break;
      case '':
        break;
      default:
        return new Error(JSON.stringify({
          CoverterError: 'Invalid Downlink Message Tyep',
          messageType: MessageType,
          messageObj: messageObj,
        }));
    }
  }
}

module.exports = Coverter;
