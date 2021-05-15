const CID = require('../lora-lib/constants');

module.exports = {
  [CID.LINKCHECK_CID]: require('./LinkCheckReq'),
  [CID.LINKADR_CID]: require('./LinkADRAns'),
  [CID.DEVSTATUS_CID]: require('./DevStatusAns'),
  [CID.RXPARAMSETUP_CID]: require('./RXParamSetupAns'),
  [CID.RXTIMINGSETUP_CID]: require('./RXTimingSetupAns'),
  [CID.NEWCHANNEL_CID]: require('./NewChannelAns'),
  [CID.DUTYCYCLE_CID]: require('./DutyCycleAns'),

  // LoRaWAN 1.1
  [CID.DEVICETIME_CID]: require('./DeviceTimeReq'),
  [CID.RESET_CID]: require('./ResetInd'),
  [CID.REKEY_CID]: require('./RekeyInd'),
  [CID.ADRPARAMSETUP_CID]: require('./ADRParamSetupAns'),
  [CID.DLCHANNEL_CID]: require('./DlChannelAns'),
  [CID.TXPARAMSETUP_CID]: require('./TxParamSetupAns'),
  [CID.REJOINPARAMSETUP_CID]: require('./RejoinParamSetupAns'),
};
