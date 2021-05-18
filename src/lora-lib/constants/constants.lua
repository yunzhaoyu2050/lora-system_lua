-- @info 静态值

local buffer = require("buffer").Buffer
-- local basexx = require("../../../deps/basexx/lib/basexx.lua")
local utiles = require("../../../utiles/utiles.lua")
local config = require("../../../server_cfg.lua")
local consts = {}

function consts.Init()
  consts.APPEUI_LEN = 8
  consts.DEVEUI_LEN = 8
  consts.GWEUI_LEN = consts.DEVEUI_LEN
  consts.DEVADDR_LEN = 4
  consts.GATEWAYID_LEN = 8
  consts.APPKEY_LEN = 16
  consts.DEVNONCE_LEN = 2
  consts.APPNONCE_LEN = 3
  consts.JOINREQ_BASIC_LENGTH = consts.APPEUI_LEN + consts.DEVEUI_LEN + consts.DEVNONCE_LEN
  consts.NETID_LEN = 3
  consts.NWKID_LEN = 1
  consts.NWKID_OFFSET = 2
  consts.DLSETTINGS_LEN = 1
  consts.DEFAULT_DLSETTINGS = buffer:new(consts.DLSETTINGS_LEN)
  consts.RX2DR_OFFSET = 0
  consts.RX2DR_LEN = 4
  consts.RX1DROFFSET_OFFSET = consts.RX2DR_OFFSET + consts.RX2DR_LEN
  consts.RX1DROFFSET_LEN = 3
  consts.OPTNEG_OFFSET = consts.RX1DROFFSET_OFFSET + consts.RX1DROFFSET_LEN
  consts.OPTNEG_LEN = 1
  consts.RXDELAY_BITOFFSET = 0
  consts.RXDELAY_BITLEN = 4
  consts.RXDELAY_LEN = 1

  consts.NWKSKEY_LEN = 16
  consts.APPSKEY_LEN = 16
  consts.DIRECTION_LEN = 1
  consts.ACTIVATION_MODE = {"OTAA", "ABP"}
  consts.BUF_LIST = {
    "AppEUI",
    "DevEUI",
    "AppKey",
    "AppNonce",
    "DevNonce",
    "AppSKey",
    "NwkSKey",
    "DevAddr",
    "NetID",
    "NwkID",
    "gatewayId",
    "identifier"
  }

  -----------------------------------------------------------------------------------------------------ism freq------------------------------------------------------------------------------------
  -- EU 433MHz ISM Band
  -- CN 470-510MHz Band
  -- China 779-787MHz ISM Band
  -- EU 863-870MHz ISM Band
  -- India 865-867 MHz ISM Band
  -- US 902-928MHz ISM Band
  -- Australia 915-928MHz ISM Band
  -- AS923MHz ISM Band
  -- South Korea 920-923MHz ISM Band

  -- consts.FREQUENCY_PLAN_LIST = {
  --   433, -- EU 433MHz ISM Band
  --   470, -- CN 470-510MHz Band
  --   779,
  --   863,
  --   865,
  --   902,
  --   915,
  --   920,
  --   923
  -- }
  consts.ISMFREQTABLE = {
    ["EU433"] = "EU433",
    ["CN470-510"] = "CN470-510",
    ["CN779-787"] = "CN779-787",
    ["US902-928"] = "US902-928",
    ["AS923AU915-928"] = "AS923AU915-928"
  }

  consts.PLANOFFSET915 = 1

  consts.GetISMFreqPLanOffset = function(rxFreq) -- 根据输入的频率获得ism频段
    if type(rxFreq) == "string" then
      if rxFreq == "EU433" then
        return "EU433"
      elseif rxFreq == "CN470-510" then
        return "CN470-510"
      elseif rxFreq == "CN779-787" then
        return "CN779-787"
      elseif rxFreq == "US902-928" then
        return "US902-928"
      elseif rxFreq == "AS923AU915-928" then
        return "AS923AU915-928"
      else
        return ""
      end
    elseif type(rxFreq) == "number" then
      if rxFreq == 433 then
        return "EU433"
      elseif rxFreq >= 470 and rxFreq <= 510 then
        return "CN470-510"
      elseif rxFreq >= 779 and rxFreq <= 787 then
        return "CN779-787"
      elseif rxFreq >= 902 and rxFreq <= 928 then
        return "US902-928"
      elseif rxFreq >= 915 and rxFreq <= 928 then
        return "AS923AU915-928"
      else
        return ""
      end
    else
      return ""
    end
  end

  consts.GetDatr = function(datr, RX1DROFFSET, freqIsmPlanOffset) -- 获得datr
    local dr = consts.DR_PARAM
    local RX1DROFFSETTABLE = dr.RX1DROFFSETTABLE[freqIsmPlanOffset]
    local DRUP = dr.DRUP[freqIsmPlanOffset]
    local DRDOWN = dr.DRDOWN[freqIsmPlanOffset]
    for key, _ in pairs(DRDOWN) do
      if RX1DROFFSETTABLE[DRUP[datr]][RX1DROFFSET] == DRDOWN[key] then
        return key
      end
    end
    return datr
  end

  consts.CFLISTJSON = {
    ["EU433"] = "330A6833029832FAC832F2F832EB2832E35832DB8832D3B8",
    ["CN470-510"] = "",
    ["CN779-787"] = "67E5A867DDD867D60867CE3867C66867BE9867B6C867AEF8",
    ["US902-928"] = "",
    ["AS923AU915-928"] = "7CC5687CBD987CB5C87CADF87CA6287C9E587C96887C8EB8"
    -- ["EU863-870"] = "756A987562C8755AF8755328754B58754388753BB87533E8",
  }

  -- 这张表中的最大EIRP的值的变化范围由各个地区来进行自行规定。
  -- Coded Value   0  1  2  3  4  5  6  7  8  9 10 11
  -- Max EIRP(dBm) 8 10 12 13 14 16 18 20 21 24 26 27
  consts.DEFAULTCHDRRANGE = "5050505050505050"
  consts.DEFAULTCONF = {
    ["EU433"] = {
      frequencyPlan = "EU433",
      ChMask = "00FF",
      CFList = consts.CFLISTJSON[433],
      ChDrRange = consts.DEFAULTCHDRRANGE,
      RX1CFList = consts.CFLISTJSON[433],
      RX2Freq = 434.665,
      RX2DataRate = 0,
      MaxEIRP = 12.15
    },
    ["CN470-510"] = {
      -- TODO: 核定
      frequencyPlan = "CN470-510",
      ChMask = "00FF",
      CFList = "",
      ChDrRange = consts.DEFAULTCHDRRANGE,
      RX1CFList = "",
      RX2Freq = 474.665,
      RX2DataRate = 0,
      MaxEIRP = 27
    },
    ["CN779-787"] = {
      frequencyPlan = "CN779-787",
      ChMask = "00FF",
      CFList = consts.CFLISTJSON[787],
      ChDrRange = consts.DEFAULTCHDRRANGE,
      RX1CFList = consts.CFLISTJSON[787],
      RX2Freq = 786.000,
      RX2DataRate = 0,
      MaxEIRP = 12.15
    },
    ["AS923AU915-928"] = {
      frequencyPlan = "AS923AU915-928",
      ChMask = "FF00000000000000FF",
      CFList = consts.CFLISTJSON[915],
      ChDrRange = consts.DEFAULTCHDRRANGE,
      RX1CFList = "7E44387E2CC87E15587DFDE87DE6787DCF087DB7987DA028",
      RX2Freq = 923.300,
      RX2DataRate = 8,
      MaxEIRP = 30
    }
    -- ["EU863-870"] = {
    --   frequencyPlan = 868,
    --   ChMask = "00FF",
    --   CFList = consts.CFLISTJSON[868],
    --   ChDrRange = consts.DEFAULTCHDRRANGE,
    --   RX1CFList = consts.CFLISTJSON[868],
    --   RX2Freq = 869.525,
    --   RX2DataRate = 0,
    --   MaxEIRP = 16
    -- },
  }

  -- Default frequency of received window (2)
  consts.DEFAULT_FREQ = {433.700, 916.700, 869.525, 786.000}

  -- Default datarate offset between received window 1 and tx
  consts.DEFAULT_RX1DROFFSET = {4, 1, 1, 1}

  -- Default datarate of received window 2
  consts.DEFAULT_RX2DR = {0, 8, 0, 0}

  -- Default RxDelay for RX1 is 1000 ms
  consts.DEFAULT_RX1DELAY = 1000

  consts.DOWNLINK_MQ_PREFIX = "lora:as:appdata:"
  consts.DOWNLINK_DELAY = 300
  consts.DEDUPLICATION_DURATION = 200
  -- consts.COLLECTKEYTEMP_PREFIX = "lora:ns:rx:collect:"
  -- consts.COLLECTLOCKKEYTEMP_PREFIX = "lora:ns:rx:collect:lock:"

  consts.MACCOMMANDPORT = buffer:new(1) -- 填充0
  utiles.BufferFill(consts.MACCOMMANDPORT, 0)

  consts.MAX_FCNT_DIFF = 50

  consts.CMDGATEWAYTXPOWE_DEFAULT = 25 -- 默认网关发射功率

  -- 获取频率表的偏移值
  consts.GetIndexFreqOffset = function(tbl, val)
    for i, v in pairs(tbl) do
      if v == val then
        return i - 1
      end
    end
    p(
      "CN 470-510MHz Band, Only supports:",
      consts.DR470510FREQTABLE,
      ", The current frequency is not in this range:",
      val
    )
    return -1
  end

  -- data rate parameters
  -- ***************************************EU 433MHz ISM Band******************************************* --
  consts.DR433 = {
    SF12BW125 = "DR0",
    SF11BW125 = "DR1",
    SF10BW125 = "DR2",
    SF9BW125 = "DR3",
    SF8BW125 = "DR4",
    SF7BW125 = "DR5",
    SF7BW250 = "DR6"
  }

  consts.RX1DROFFSET433TABLE = {
    DR0 = {"DR0", "DR0", "DR0", "DR0", "DR0", "DR0"}, -- Array(6).fill("DR0"),
    DR1 = {"DR1", "DR0", "DR0", "DR0", "DR0", "DR0"},
    DR2 = {"DR2", "DR1", "DR0", "DR0", "DR0", "DR0"},
    DR3 = {"DR3", "DR2", "DR1", "DR0", "DR0", "DR0"},
    DR4 = {"DR4", "DR3", "DR2", "DR1", "DR0", "DR0"},
    DR5 = {"DR5", "DR4", "DR3", "DR2", "DR1", "DR0"},
    DR6 = {"DR6", "DR5", "DR4", "DR3", "DR2", "DR1"},
    DR7 = {"DR7", "DR6", "DR5", "DR4", "DR3", "DR2"}
  }

  consts.RX1DROFFSET433 = 4
  -- *************************************************************************************************************** --
  -- ***********************************************CN 470-510MHz Band********************************************** --
  consts.DR470510 = {
    SF12BW125 = "DR0", -- 250 bit/sec
    SF11BW125 = "DR1", -- 440
    SF10BW125 = "DR2", -- 980
    SF9BW125 = "DR3", -- 1760
    SF8BW125 = "DR4", -- 3125
    SF7BW125 = "DR5" -- 5470
  }

  consts.RX1DROFFSET470510TABLE = {
    DR0 = {"DR0", "DR0", "DR0", "DR0", "DR0", "DR0"},
    DR1 = {"DR1", "DR0", "DR0", "DR0", "DR0", "DR0"},
    DR2 = {"DR2", "DR1", "DR0", "DR0", "DR0", "DR0"},
    DR3 = {"DR3", "DR2", "DR1", "DR0", "DR0", "DR0"},
    DR4 = {"DR4", "DR3", "DR2", "DR1", "DR0", "DR0"},
    DR5 = {"DR5", "DR4", "DR3", "DR2", "DR1", "DR0"}
  }

  --  2.6.9 CN470-510 Default Settings
  --  The following parameters are recommended values for the CN470-510 band.
  --  RECEIVE_DELAY1 1 s
  --  RECEIVE_DELAY2 2 s (must be RECEIVE_DELAY1 + 1s)
  --  JOIN_ACCEPT_DELAY1 5 s
  --  JOIN_ACCEPT_DELAY2 6 s
  --  MAX_FCNT_GAP 16384
  --  ADR_ACK_LIMIT 64
  --  ADR_ACK_DELAY 32
  --  ACK_TIMEOUT 2 +/- 1 s (random delay between 1 and 3 seconds)

  consts.RX1DROFFSET470510 = 4

  -- 支持的频率表
  consts.DR470510FREQTABLE = {
    470.300000,
    470.500000,
    470.700000,
    470.900000,
    471.100000,
    471.300000,
    471.500000,
    471.700000
  }

  consts.CN470510_STEPWIDTH_RX1_CHANNEL = 0.200000
  consts.CN470510_FIRST_RX1_CHANNEL = 500.300000

  -- consts.CN470510_CMDGATEWAYTXPOWE_DEFAULT = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25}
  -- *************************************************************************************************************** --
  -- ***************************************Australia 915-928MHz ISM Band******************************************* --
  consts.DR915UP = {
    SF10BW125 = "DR0",
    SF9BW125 = "DR1",
    SF8BW125 = "DR2",
    SF7BW125 = "DR3",
    SF8BW500 = "DR4"
  }

  consts.DR915DOWN = {
    SF12BW500 = "DR8",
    SF11BW500 = "DR9",
    SF10BW500 = "DR10",
    SF9BW500 = "DR11",
    SF8BW500 = "DR12",
    SF7BW500 = "DR13"
  }

  consts.RX1DROFFSET915TABLE = {
    DR0 = {"DR10", "DR9", "DR8", "DR8"},
    DR1 = {"DR11", "DR10", "DR9", "DR8"},
    DR2 = {"DR12", "DR11", "DR10", "DR9"},
    DR3 = {"DR13", "DR12", "DR11", "DR10"},
    DR4 = {"DR13", "DR13", "DR12", "DR11"},
    DR8 = {"DR8", "DR8", "DR8", "DR8"},
    DR9 = {"DR9", "DR8", "DR8", "DR8"},
    DR10 = {"DR10", "DR9", "DR8", "DR8"},
    DR11 = {"DR11", "DR10", "DR9", "DR8"},
    DR12 = {"DR12", "DR11", "DR10", "DR9"},
    DR13 = {"DR13", "DR12", "DR11", "DR10"}
  }

  consts.RX1DROFFSET915 = 1
  -- *************************************************************************************************************** --

  consts.DR_PARAM = {
    RX1DROFFSETTABLE = {
      ["EU433"] = consts.RX1DROFFSET433TABLE,
      ["CN470-510"] = consts.RX1DROFFSET470510TABLE,
      ["AS923AU915-928"] = consts.RX1DROFFSET915TABLE
    },
    DRUP = {
      ["EU433"] = consts.DR433,
      ["CN470-510"] = consts.DR470510,
      ["AS923AU915-928"] = consts.DR915UP
    },
    DRDOWN = {
      ["EU433"] = consts.DR433,
      ["CN470-510"] = consts.DR470510,
      ["AS923AU915-928"] = consts.DR915DOWN
    },
    RX1DROFFSET = {
      ["EU433"] = consts.RX1DROFFSET433,
      ["CN470-510"] = consts.RX1DROFFSET470510,
      ["AS923AU915-928"] = consts.RX1DROFFSET915
    } -- FIXME delete me, DeviceConfig
  }

  -- Default configuration of txpk
  consts.TXPK_CONFIG = {
    TMST_OFFSET = 1000000, -- 1s
    TMST_OFFSET_JOIN = 5000000, -- 5s
    FREQ = {
      ["EU433"] = function(callBack)
        return callBack()
      end,
      ["CN470-510"] = function(callBack)
        local indexOffset = consts.GetIndexFreqOffset(consts.DR470510FREQTABLE, callBack())
        if indexOffset < 0 then
          return 0
        end
        return consts.CN470510_FIRST_RX1_CHANNEL + (indexOffset % 48) * consts.CN470510_STEPWIDTH_RX1_CHANNEL
      end,
      ["AS923AU915-928"] = function(callBack)
        return 923.3 + (callBack() % 8) * 0.6
      end,
      ["CN779-787"] = function(callBack)
        return callBack()
      end
    },
    POWE = {
      ["EU433"] = function()
        return 25
      end,
      ["CN470-510"] = function()
        local cfgPowe = config.GetCmdGatewwayTxPowe()
        if cfgPowe ~= nil then
          return cfgPowe
        end
        return consts.CMDGATEWAYTXPOWE_DEFAULT
      end,
      ["AS923AU915-928"] = function()
        return 20
      end,
      ["CN779-787"] = function()
        return 20
      end
    }
  }
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  consts.RXDELAY_LEN = 1
  consts.DEFAULT_RXDELAY = buffer:new(consts.RXDELAY_LEN)

  -- Constants for PHY payload parsing
  consts.MHDR_OFFSET = 0
  consts.MHDR_LEN = 1
  consts.MACPAYLOAD_OFFSET = consts.MHDR_OFFSET + consts.MHDR_LEN
  consts.MHDR_END = consts.MACPAYLOAD_OFFSET

  -- MHDR parsing
  consts.MTYPE_OFFSET = 5
  consts.MTYPE_LEN = 3
  consts.MAJOR_OFFSET = 0
  consts.MAJOR_LEN = 2
  consts.MAJOR_DEFAULT = 0

  consts.MIC_LEN = 4

  -- MType位字段
  consts.JOIN_REQ = 0
  consts.JOIN_ACCEPT = 1
  consts.UNCONFIRMED_DATA_UP = 2
  consts.UNCONFIRMED_DATA_DOWN = 3
  consts.CONFIRMED_DATA_UP = 4
  consts.CONFIRMED_DATA_DOWN = 5
  consts.REJOIN_REQ = 6
  consts.PROPRIETARY = 7

  -- Data message type list
  consts.NS_MSG_TYPE_LIST = {
    consts.JOIN_REQ,
    consts.JOIN_ACCEPT,
    consts.UNCONFIRMED_DATA_UP,
    consts.UNCONFIRMED_DATA_DOWN,
    consts.CONFIRMED_DATA_UP,
    consts.CONFIRMED_DATA_DOWN,
    consts.REJOIN_REQ,
    consts.PROPRIETARY
  }

  -- Join message type list
  consts.JS_MSG_TYPE = {
    request = consts.JOIN_REQ,
    accept = consts.JOIN_ACCEPT,
    rejoin = consts.REJOIN_REQ
  }

  -- consts.JS_MSG_TYPE_LIST = Object.values(consts.JS_MSG_TYPE);
  consts.JS_MSG_TYPE_LIST = {consts.JOIN_REQ}

  -- UDP message version
  consts.UDP_VERSION_LIST = {0x01, 0x02}

  -- UDP payload offset and length, prefix = UDP
  consts.UDP_VERSION_LEN = 1
  consts.UDP_VERSION_OFFSET = 0
  consts.UDP_TOKEN_LEN = 2
  consts.UDP_TOKEN_OFFSET = consts.UDP_VERSION_OFFSET + consts.UDP_VERSION_LEN
  consts.UDP_IDENTIFIER_LEN = 1
  consts.UDP_IDENTIFIER_OFFSET = consts.UDP_TOKEN_OFFSET + consts.UDP_TOKEN_LEN
  consts.PULL_DATA_LENGTH =
    consts.UDP_IDENTIFIER_LEN + consts.UDP_VERSION_LEN + consts.UDP_TOKEN_LEN + consts.GATEWAYID_LEN
  consts.PUSH_DATA_BASIC_LENGTH = consts.PULL_DATA_LENGTH
  consts.UDP_DATA_BASIC_LENGTH = consts.PULL_DATA_LENGTH

  -- UDP identifier
  consts.UDP_ID_PUSH_DATA = 0x00
  consts.UDP_ID_PUSH_ACK = 0x01
  consts.UDP_ID_PULL_DATA = 0x02
  consts.UDP_ID_PULL_RESP = 0x03
  consts.UDP_ID_PULL_ACK = 0x04
  consts.UDP_ID_TX_ACK = 0x05
  -- UDP identifier string
  consts.UDP_IDENTIFIER = {
    [consts.UDP_ID_PUSH_DATA] = "PUSH_DATA",
    [consts.UDP_ID_PUSH_ACK] = "PUSH_ACK",
    [consts.UDP_ID_PULL_DATA] = "PULL_DATA",
    [consts.UDP_ID_PULL_RESP] = "PULL_RESP",
    [consts.UDP_ID_PULL_ACK] = "PULL_ACK",
    [consts.UDP_ID_TX_ACK] = "TX_ACK"
  }

  -- UDP PUSH_DATA
  consts.UDP_GW_ID_OFFSET = consts.UDP_IDENTIFIER_OFFSET + consts.UDP_IDENTIFIER_LEN
  consts.UDP_JSON_OBJ_OFFSET = consts.UDP_GW_ID_OFFSET + consts.GATEWAYID_LEN

  consts.UDP_DOWNLINK_BASIC_LEN = consts.UDP_VERSION_LEN + consts.UDP_TOKEN_LEN + consts.UDP_IDENTIFIER_LEN

  -- UDP PUSH_ACK
  consts.UDP_PUSH_ACK_LEN = consts.UDP_DOWNLINK_BASIC_LEN
  -- UDP PULL_DATA same as PUSH_DATA

  -- UDP PULL_ACK
  consts.UDP_PULL_ACK_LEN = consts.UDP_DOWNLINK_BASIC_LEN + consts.GATEWAYID_LEN

  -- UDP PULL_RESP
  consts.UDP_PULL_RESP_PAYLOAD_OFFSET = consts.UDP_GW_ID_OFFSET
  consts.UDP_PULL_RESP_PAYLOAD_BASIC_LEN = consts.UDP_DOWNLINK_BASIC_LEN

  -- UDP TX_ACK same as PULL_RESP
  consts.UDP_TX_ACK_PAYLOAD_OFFSET = consts.UDP_JSON_OBJ_OFFSET

  consts.UDP_PACKAGE_ENCODING = "ascii"
  consts.DATA_ENCODING = "base64"

  -- MAC payload offset, prefix = MP
  consts.MP_DEVADDR_OFFSET = 0
  consts.MP_FHDR_OFFSET = 0
  consts.MP_FCTRL_OFFSET = consts.MP_DEVADDR_OFFSET + consts.DEVADDR_LEN
  consts.MP_DEVADDR_END = consts.MP_FCTRL_OFFSET
  consts.FCTRL_LEN = 1
  consts.MP_FCNT_OFFSET = consts.MP_FCTRL_OFFSET + consts.FCTRL_LEN
  consts.MP_FCTRL_END = consts.MP_FCNT_OFFSET
  consts.FCNT_LEN = 4
  consts.MP_FCNT_LEN = 2
  consts.FCNT_LEAST_OFFSET = 2
  consts.FHDR_LEN_BASE = consts.DEVADDR_LEN + consts.FCTRL_LEN + consts.MP_FCNT_LEN
  consts.MP_FOPTS_OFFSET = consts.MP_FCNT_OFFSET + consts.MP_FCNT_LEN
  consts.MP_FCNT_END = consts.MP_FOPTS_OFFSET
  consts.FOPTS_MAXLEN = 15
  -- FCTRL bitwise offset, prefix = FC, bit length
  consts.FC_FOPTSLEN_OFFSET = 0
  consts.FOPTSLEN = 4
  consts.FC_FPENDING_OFFSET = consts.FC_FOPTSLEN_OFFSET + consts.FOPTSLEN
  consts.FPENDING_LEN = 1
  consts.FC_ACK_OFFSET = consts.FC_FPENDING_OFFSET + consts.FPENDING_LEN
  consts.ACK_LEN = 1
  consts.FC_CLASSB_OFFSET = consts.FC_ACK_OFFSET + consts.ACK_LEN
  consts.CLASSB_LEN = 1
  consts.RFU_LEN = 1
  consts.FC_ADR_OFFSET = consts.FC_ACK_OFFSET + consts.ACK_LEN + consts.RFU_LEN
  consts.ADR_LEN = 1
  consts.FC_ADRACKREQ_OFFSET = consts.FC_ACK_OFFSET + consts.ACK_LEN
  consts.ADRACKREQ_LEN = 1

  consts.FPORT_LEN = 1

  consts.MIN_MACPAYLOAD_LEN = consts.FHDR_LEN_BASE
  consts.MIN_PHYPAYLOAD_LEN = consts.MHDR_LEN + consts.MIN_MACPAYLOAD_LEN + consts.MIC_LEN

  -- For join request
  consts.JOINEUI_OFFSET = 0
  consts.JOINEUI_LEN = 8
  consts.DEVEUI_OFFSET = consts.JOINEUI_OFFSET + consts.JOINEUI_LEN
  consts.DEVNONCE_OFFSET = consts.DEVEUI_OFFSET + consts.DEVEUI_LEN
  consts.JOINREQ_BASIC_LENGTH = consts.APPEUI_LEN + consts.DEVEUI_LEN + consts.DEVNONCE_LEN

  -- MIC and encrypt block
  consts.BLOCK_CLASS = {
    A = 0x01,
    B = 0x49
  }

  consts.BLOCK_DIR_CLASS = {
    Up = 0x00,
    Down = 0x01
  }

  consts.BLOCK_LEN = 16
  consts.BLOCK_DIR_OFFSET = 5
  consts.BLOCK_DIR_LEN = 1
  consts.BLOCK_DEVADDR_OFFSET = consts.BLOCK_DIR_OFFSET + consts.BLOCK_DIR_LEN
  consts.BLOCK_FCNT_OFFSET = consts.BLOCK_DEVADDR_OFFSET + consts.DEVADDR_LEN
  consts.BLOCK_LENMSG_OFFSET = consts.BLOCK_FCNT_OFFSET + consts.FCNT_LEN + 1
  consts.IV_LEN = consts.BLOCK_LEN

  consts.BLOCK_LEN_REQ_MIC = consts.MHDR_LEN + consts.APPEUI_LEN + consts.DEVEUI_LEN + consts.DEVNONCE_LEN

  consts.BLOCK_LEN_ACPT_BASE =
    consts.APPNONCE_LEN + consts.NETID_LEN + consts.DEVADDR_LEN + consts.DLSETTINGS_LEN + consts.RXDELAY_LEN
  consts.BLOCK_LEN_ACPT_MIC_BASE = consts.MHDR_LEN + consts.BLOCK_LEN_ACPT_BASE

  consts.LENMSG_LEN = 1

  consts.V102_CMAC_LEN = 4
  consts.V11_CMAC_LEN = 2

  -- ants for XCloud
  consts.DID_LEN = 22
  consts.PK_LEN = 32 -- Product key
  consts.SESSKEYBUF_LEN = 1 + consts.APPNONCE_LEN + consts.DEVNONCE_LEN + consts.NETID_LEN
  consts.SK_APPNONCE_OFFSET = 1
  consts.SK_NETID_OFFSET = consts.SK_APPNONCE_OFFSET + consts.APPNONCE_LEN
  consts.SK_DEVNONCE_OFFSET = consts.SK_NETID_OFFSET + consts.NETID_LEN

  -- Default RxDelay for RX1 is 1 sec.
  consts.DEFAULT_RXDELAY = buffer:new(consts.RXDELAY_LEN)

  consts.NS_SUB_TOPIC = "NS-sub-test"
  consts.NC_SUB_TOPIC = "NC-sub-test"

  consts.HASH_METHOD = "md5"
  consts.ENCRYPTION_ALGO = "aes-128-ecb"
  consts.ENCRYPTION_AES128 = "aes-128"

  consts.JR_APPEUI_OFFSET = 0

  consts.MESSAGE_ID_LEN = 4

  consts.MACCMDQUEANS_PREFIX = "lora:nc:maccommand:ans:"
  consts.MACCMDQUEREQ_PREFIX = "lora:nc:maccommand:req:"

  consts.QUEUE_CMDANS_LIST = {0x01, 0x02, 0x0B, 0x0D}

  -- MACCommand
  consts.CID_LEN = 1
  consts.CID_OFFEST = 0
  consts.PAYLOAD_OFFEST = 1

  consts.RESET_CID = 0x01
  consts.RESETIND_LEN = 1
  consts.RESETCONF_LEN = 1
  consts.RESETIND = {
    MINOR_START = 0,
    MINOR_LEN = 4
  }

  consts.LINKCHECK_CID = 0x02
  consts.LINKCHECKREQ_LEN = 0
  consts.LINKCHECKANS_LEN = 2
  consts.LINKCHECKANS = {
    MARGIN_LEN = 1,
    GWCNT_LEN = 1
  }

  consts.LINKADR_CID = 0x03
  consts.LINKADRANS_LEN = 1
  consts.LINKADRREQ_LEN = 4
  consts.LINKADRREQ = {
    DATARATE_TXPOWER_LEN = 1,
    CHMASK_LEN = 2,
    REDUNDANCY_LEN = 1,
    DATARATE_BASE = 16,
    TXPOWER_BASE = 1, -- DataRate_TXPower = DataRate * DATARATE_BASE + TXPower * TXPOWER_BASE
    CHMASKCNTL_BASE = 16,
    NBTRANS_BASE = 1, -- Redundancy = ChMaskCntl * CHMASKCNTL_BASE + NbTrans * NBTRANS_BASE
    DATARATE_DEFAULT = 15, -- keep datarate of device unchanged
    TXPOWER_DEFAULT = 15, -- keep txpower of device unchanged
    NBTRANS_DEFAULT = 0 -- keep nbtrans unchanged
  }
  consts.LINKADRANS = {
    CHANNELMASKACK_START = 0,
    CHANNELMASKACK_LEN = 1,
    DATARATEACK_START = 1,
    DATARATEACK_LEN = 1,
    POWERACK_START = 2,
    POWERACK_LEN = 1
  }

  consts.DUTYCYCLE_CID = 0x04
  consts.DUTYCYCLEANS_LEN = 0
  consts.DUTYCYCLEREQ_LEN = 1
  consts.DUTYCYCLEREQ = {
    MAXCYCLE_BASE = 1,
    DUTYCYCLEPL_LEN = 1
  }

  consts.RXPARAMSETUP_CID = 0x05
  consts.RXPARAMSETUPANS_LEN = 1
  consts.RXPARAMSETUPREQ_LEN = 4
  consts.RXPARAMSETUPREQ = {
    FREQUENCY_LEN = 3,
    DLSETTINGS_LEN = 1,
    RX2DATARATE_BASE = 1,
    RX1DROFFSET_BASE = 16 -- DLSettings = RX1DRoffset * RX1DROFFSET_BASE + RX2DataRate * RX2DATARATE_BASE
  }
  consts.RXPARAMSETUPANS = {
    CHANNELACK_START = 0,
    CHANNELACK_LEN = 1,
    RX2DATARATEACK_START = 1,
    RX2DATARATEACK_LEN = 1,
    RX1DROFFSETACK_START = 2,
    RX1DROFFSETACK_LEN = 1
  }

  consts.DEVSTATUS_CID = 0x06
  consts.DEVSTATUSANS_LEN = 2
  consts.BATTERY_LEN = 1
  consts.DEVSTATUSREQ_LEN = 0
  consts.DEVSTATUSANS = {
    BATTERY_START = 0,
    BATTERY_LEN = 1,
    MARGIN_START = 1,
    MARGIN_LEN = 1
  }

  consts.NEWCHANNEL_CID = 0x07
  consts.NEWCHANNELANS_LEN = 1
  consts.NEWCHANNELREQ_LEN = 5
  consts.NEWCHANNELREQ = {
    CHINDEX_LEN = 1,
    FREQ_LEN = 3,
    DRRANGE_LEN = 1,
    MAXDR_BASE = 16,
    MINDR_BASE = 1 -- DrRange = MaxDR * MAXDR_BASE + MinDR * MINDR_BASE
  }
  consts.NEWCHANNELANS = {
    CHANNELFREQUENCY_START = 0,
    CHANNEKFREQUENCY_LEN = 1,
    DATARATERANGE_START = 1,
    DATARATERANGE_LEN = 1
  }

  consts.RXTIMINGSETUP_CID = 0x08
  consts.RXTIMINGSETUPANS_LEN = 0
  consts.RXTIMINGSETUPREQ_LEN = 1
  consts.RXTIMINGSETUPREQ = {
    SETTINGS_LEN = 1
  }

  consts.TXPARAMSETUP_CID = 0x09
  consts.TXPARAMSETUPANS_LEN = 0
  consts.TXPARAMSETUPREQ_LEN = 1
  consts.TXPARAMSETUPREQ = {
    EIRP_DWELLTIME_LEN = 1,
    DOWNLINKDWELLTIME_BASE = 32,
    UPLINKDWELLTIME_BASE = 16,
    MAXEIRP_BASE = 1 -- EIRP_DwellTime = DownlinkDwellTime * DOWNLINKDWELLTIME_BASE + UplinkDwellTime * UPLINKDWELLTIME_BASE + MaxEIRP * MAXEIRP_BASE
  }

  consts.DLCHANNEL_CID = 0x0A
  consts.DLCHANNELANS_LEN = 1
  consts.DLCHANNELREQ_LEN = 4
  consts.DLCHANNELREQ = {
    CHINDEX_LEN = 1,
    FREQ_LEN = 3
  }
  consts.DLCHANNELANS = {
    CHANNELFREQUENCY_START = 0,
    CHANNELFREQUENCY_LEN = 1,
    UPLINKFREQUENCY_START = 1,
    UPLINKFREQUENCY_LEN = 1
  }

  consts.REKEY_CID = 0x0B
  consts.REKEYIND_LEN = 1
  consts.REKEYCONF_LEN = 1
  consts.REKEYIND = {
    MINOR_START = 0,
    MINOR_LEN = 4
  }

  consts.ADRPARAMSETUP_CID = 0x0C
  consts.ADRPARAMSETUPANS_LEN = 0
  consts.ADRPARAMSETUPREQ_LEN = 1
  consts.ADRPARAMSETUPREQ = {
    ADRPARAM_LEN = 1,
    LIMIT_EXP_BASE = 16,
    DELAY_EXP_BASE = 1 -- ADRparam = Limit_exp * LIMIT_EXP_BASE + Delay_exp * DELAY_EXP_BASE
  }

  consts.DEVICETIME_CID = 0x0D
  consts.DEVICETIMEREQ_LEN = 0
  consts.DEVICETIMEANS_LEN = 5
  consts.DEVICETIMEANS = {
    FRACTIONALSEC_LEN = 1,
    SECONDS_LEN = 4
  }

  consts.FORCEREJOIN_CID = 0x0E
  consts.FORCEREJOINREQ_LEN = 2
  consts.FORCEREJOINREQ = {
    PERIOD_BASE = 1024,
    MAX_RETRIES_BASE = 256,
    REJOINTYPE_BASE = 16,
    DR_BASE = 1 -- ForcerRejoinReq = Period * PERIOD_BASE + Max_Retries * MAX_RETRIES_BASE + RejoinType * REJOINTYPE_BASE + DR * DR_BASE
  }

  consts.REJOINPARAMSETUP_CID = 0x0F
  consts.REJOINPARAMSETUPANS_LEN = 1
  consts.REJOINPARAMSETUPREQ_LEN = 1
  consts.REJOINPARAMSETUPREQ = {
    MAXTIMEN_BASE = 16,
    MAXCOUNTN_BASE = 1 -- RejoinParamSetupReq = MaxTimeN * MAXTIMEN_BASE + MacCountN * MAXCOUNTN_BASE
  }
  consts.REJOINPARAMSETUPANS = {
    TIMEOK_START = 0,
    TIMEOK_LEN = 1
  }

  consts.MACCMD_DOWNLINK_LIST = {
    [consts.RESET_CID] = consts.RESETCONF_LEN,
    [consts.LINKCHECK_CID] = consts.LINKCHECKANS_LEN,
    [consts.LINKADR_CID] = consts.LINKADRREQ_LEN,
    [consts.DUTYCYCLE_CID] = consts.DUTYCYCLEREQ_LEN,
    [consts.RXPARAMSETUP_CID] = consts.RXPARAMSETUPREQ_LEN,
    [consts.DEVSTATUS_CID] = consts.DEVSTATUSREQ_LEN,
    [consts.NEWCHANNEL_CID] = consts.NEWCHANNELREQ_LEN,
    [consts.RXTIMINGSETUP_CID] = consts.RXTIMINGSETUPREQ_LEN,
    [consts.TXPARAMSETUP_CID] = consts.TXPARAMSETUPREQ_LEN,
    [consts.DLCHANNEL_CID] = consts.DLCHANNELREQ_LEN,
    [consts.REKEY_CID] = consts.REKEYCONF_LEN,
    [consts.ADRPARAMSETUP_CID] = consts.ADRPARAMSETUPREQ_LEN,
    [consts.DEVICETIME_CID] = consts.DEVICETIMEANS_LEN,
    [consts.FORCEREJOIN_CID] = consts.FORCEREJOINREQ_LEN,
    [consts.REJOINPARAMSETUP_CID] = consts.REJOINPARAMSETUPREQ_LEN
  }

  consts.MACCMD_UPLINK_LIST = {
    [consts.RESET_CID] = consts.RESETIND_LEN,
    [consts.LINKCHECK_CID] = consts.LINKCHECKREQ_LEN,
    [consts.LINKADR_CID] = consts.LINKADRANS_LEN,
    [consts.DUTYCYCLE_CID] = consts.DUTYCYCLEANS_LEN,
    [consts.RXPARAMSETUP_CID] = consts.RXPARAMSETUPANS_LEN,
    [consts.DEVSTATUS_CID] = consts.DEVSTATUSANS_LEN,
    [consts.NEWCHANNEL_CID] = consts.NEWCHANNELANS_LEN,
    [consts.RXTIMINGSETUP_CID] = consts.RXTIMINGSETUPANS_LEN,
    [consts.TXPARAMSETUP_CID] = consts.TXPARAMSETUPANS_LEN,
    [consts.DLCHANNEL_CID] = consts.DLCHANNELANS_LEN,
    [consts.REKEY_CID] = consts.REKEYIND_LEN,
    [consts.ADRPARAMSETUP_CID] = consts.ADRPARAMSETUPANS_LEN,
    [consts.DEVICETIME_CID] = consts.DEVICETIMEREQ_LEN,
    [consts.REJOINPARAMSETUP_CID] = consts.REJOINPARAMSETUPANS_LEN
  }

  -- Required Demodulator SNR (/dB) of LoRa modem
  consts.SF_REQUIREDSNR = {
    ["12"] = -20,
    ["11"] = -17.5,
    ["10"] = -15,
    ["9"] = -12.5,
    ["8"] = -10,
    ["7"] = -7.5,
    ["6"] = -5
  }

  consts.ADR_CONTROLSCHEME_PARAM = {
    LATEST_SNR_NO = 20,
    DEVICEMARGIN = 10,
    STEPS_DIVISOR = 3,
    SF_STEP = 1,
    TXPOWER_STEP = 1,
    CHMASK_DEFAULT = "00FF",
    CHMASKCNTL_DEFAULT = {
      [consts.ISMFREQTABLE["EU433"]] = 6,
      [consts.ISMFREQTABLE["CN470-510"]] = 5,
      [consts.ISMFREQTABLE["CN779-787"]] = 6,
      [consts.ISMFREQTABLE["AS923AU915-928"]] = 6
    },
    NBTRANS_DEFAULT = consts.LINKADRREQ.NBTRANS_DEFAULT
  }

  consts.MAX_FRMPAYLOAD_SIZE_REPEATER = {
    ["EU433"] = {
      SF12BW125 = 51,
      SF11BW125 = 51,
      SF10BW125 = 51,
      SF9BW125 = 115,
      SF8BW125 = 222,
      SF7BW125 = 222,
      SF7BW250 = 222
    },
    ["AS923AU915-928"] = {
      SF12BW125 = 51,
      SF11BW125 = 51,
      SF10BW125 = 51,
      SF9BW125 = 115,
      SF8BW125 = 222,
      SF7BW125 = 222,
      SF8BW500 = 222,
      SF12BW500 = 33,
      SF11BW500 = 109,
      SF10BW500 = 222,
      SF9BW500 = 222,
      -- SF8BW500 = 222,
      SF7BW500 = 222
    },
    ["CN470-510"] = {
      SF12BW125 = 222,
      SF11BW125 = 222,
      SF10BW125 = 222,
      SF9BW125 = 222,
      SF8BW125 = 222,
      SF7BW125 = 222
    }
  }
  consts.MAX_FRMPAYLOAD_SIZE_NOREPEATER = {
    ["EU433"] = {
      SF12BW125 = 51,
      SF11BW125 = 51,
      SF10BW125 = 51,
      SF9BW125 = 115,
      SF8BW125 = 242,
      SF7BW125 = 242,
      SF7BW250 = 242
    },
    ["AS923AU915-928"] = {
      SF12BW125 = 51,
      SF11BW125 = 51,
      SF10BW125 = 51,
      SF9BW125 = 115,
      SF8BW125 = 242,
      SF7BW125 = 242,
      SF8BW500 = 242,
      SF12BW500 = 53,
      SF11BW500 = 129,
      SF10BW500 = 242,
      SF9BW500 = 242,
      -- SF8BW500 = 242,
      SF7BW500 = 242
    },
    ["CN470-510"] = {
      SF12BW125 = 242,
      SF11BW125 = 242,
      SF10BW125 = 242,
      SF9BW125 = 242,
      SF8BW125 = 242,
      SF7BW125 = 242
    }
  }
  consts.TXPOWER_MAX_LIST = {
    [consts.ISMFREQTABLE["EU433"]] = 5,
    [consts.ISMFREQTABLE["CN470-510"]] = 10,
    [consts.ISMFREQTABLE["CN779-787"]] = 7,
    [consts.ISMFREQTABLE["AS923AU915-928"]] = 5
  }

  consts.TXPOWER_MIN = 0

  consts.SPREADFACTOR_MIN = 7

  -- consts.MONGO_USERCOLLECTION_PREFIX = "lora_user_"
  -- consts.MONGO_JOINMSGCOLLECTION = "lora_join"
  -- consts.MONGO_APPMSGCOLLECTION_PREFIX = "lora_appeui_"
  -- consts.MONGO_SAVEDMSG_TYPE = {
  --     uplink_joinReq = "UPLINK_JOINREQ",
  --     uplink_msg = "UPLINK_MSG",
  --     uplink_gatewayStat = "GATEWAYSTAT",
  --     downlink_joinAns = "DONWLINK_JOINANS",
  --     downlink_msg = "DOWNLINK_MSG"
  -- }

  -- Cache attributes
  consts.DEVICEINFO_CACHE_ATTRIBUTES = {
    -- 设备信息
    "AppKey",
    "AppEUI",
    "NwkSKey",
    "AppSKey",
    "FCntUp",
    "NFCntDown",
    "AFCntDown",
    "ProtocolVersion"
  }
  consts.DEVICECONFIG_CACHE_ATTRIBUTES = {
    -- 设备配置信息
    "frequencyPlan",
    "ADR",
    "RX1DRoffset",
    "RX1Delay"
  }
  consts.DEVICEROUTING_CACHE_ATTRIBUTES = {
    -- 设备路由信息
    "gatewayId",
    "imme",
    "tmst",
    "freq",
    "rfch",
    "powe",
    "datr",
    "modu",
    "codr",
    "ipol"
  }
  return 0
end
return consts
