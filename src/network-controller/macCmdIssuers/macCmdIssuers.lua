local CID = require("../../lora-lib/constants/constants.lua")

return {
  [CID.LINKADR_CID] = require("./LinkADRReq.lua"),
  [CID.DEVSTATUS_CID] = require("./DevStatusReq.lua"),
  [CID.RXPARAMSETUP_CID] = require("./RXParamSetupReq.lua"),
  [CID.RXTIMINGSETUP_CID] = require("./RXTimingSetupReq.lua"),
  [CID.NEWCHANNEL_CID] = require("./NewChannelReq.lua"),
  [CID.DUTYCYCLE_CID] = require("./DutyCycleReq.lua"),
  [CID.DEVICETIME_CID] = require("./DeviceTimeAns.lua"),
  [CID.REKEY_CID] = require("./RekeyConf.lua"),
  [CID.RESET_CID] = require("./ResetConf.lua"),
  -- LoRaWAN 1.1
  [CID.ADRPARAMSETUP_CID] = require("./ADRParamSetupReq.lua"),
  [CID.DLCHANNEL_CID] = require("./DlChannelReq.lua"),
  [CID.TXPARAMSETUP_CID] = require("./TxParamSetupReq.lua"),
  [CID.FORCEREJOIN_CID] = require("./ForceRejoinReq.lua"),
  [CID.REJOINPARAMSETUP_CID] = require("./RejoinParamSetupReq.lua")
}
