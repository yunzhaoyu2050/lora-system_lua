const CID = require('../lora-lib/constants');

module.exports = {
  [CID.LINKADR_CID]: require('./LinkADRReq'),
  [CID.DEVSTATUS_CID]: require('./DevStatusReq'),
  [CID.RXPARAMSETUP_CID]: require('./RXParamSetupReq'),
  [CID.RXTIMINGSETUP_CID]: require('./RXTimingSetupReq'),
  [CID.NEWCHANNEL_CID]: require('./NewChannelReq'),
  [CID.DUTYCYCLE_CID]: require('./DutyCycleReq'),
  [CID.DEVICETIME_CID]: require('./DeviceTimeAns'),
  [CID.REKEY_CID]: require('./RekeyConf'),
  [CID.RESET_CID]: require('./ResetConf'),

  // LoRaWAN 1.1
  [CID.ADRPARAMSETUP_CID]: require('./ADRParamSetupReq'),
  [CID.DLCHANNEL_CID]: require('./DlChannelReq'),
  [CID.TXPARAMSETUP_CID]: require('./TxParamSetupReq'),
  [CID.FORCEREJOIN_CID]: require('./ForceRejoinReq'),
  [CID.REJOINPARAMSETUP_CID]: require('./RejoinParamSetupReq'),
};
