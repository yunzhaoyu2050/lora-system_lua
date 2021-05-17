local CID = require("../../lora-lib/constants/constants.lua")

return {
  [CID.LINKCHECK_CID] = require("./LinkCheckReq.lua"),
  [CID.LINKADR_CID] = require("./LinkADRAns.lua"),
  [CID.DEVSTATUS_CID] = require("./DevStatusAns.lua"),
  [CID.RXPARAMSETUP_CID] = require("./RXParamSetupAns.lua"),
  [CID.RXTIMINGSETUP_CID] = require("./RXTimingSetupAns.lua"),
  [CID.NEWCHANNEL_CID] = require("./NewChannelAns.lua"),
  [CID.DUTYCYCLE_CID] = require("./DutyCycleAns.lua"),
  -- LoRaWAN 1.1
  [CID.DEVICETIME_CID] = require("./DeviceTimeReq.lua"),
  [CID.RESET_CID] = require("./ResetInd.lua"),
  [CID.REKEY_CID] = require("./RekeyInd.lua"),
  [CID.ADRPARAMSETUP_CID] = require("./ADRParamSetupAns.lua"),
  [CID.DLCHANNEL_CID] = require("./DlChannelAns.lua"),
  [CID.TXPARAMSETUP_CID] = require("./TxParamSetupAns.lua"),
  [CID.REJOINPARAMSETUP_CID] = require("./RejoinParamSetupAns.lua")
}
