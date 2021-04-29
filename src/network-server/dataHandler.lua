-- network-server 数据处理部分
-- local mqHandle = require('../src/common/message_queue.lua')
local DataConverter = require('./dataConverter.lua');
local utiles = require("../../utiles/utiles.lua")

function process(data) 
  if data == nil then
    p('data is nil')
    return nil
  end
  p('Data handler started...')
  if data.type == nil or type(data.type) ~= 'string' then
    p('data.type is nil', data)
    return nil
  end
  if data.data == nil then
    p("data.data is nil", data)
    return nil
  end
  utiles.switch(data.type) {
    ['ConnectorPubToServer']=function() -- Network Connector --> Network Server
      DataConverter.uplinkDataHandler(data.data)
    end,
    ['ControllerPubToServer']=function() -- Control Server --> Network Server
    end,
    ['JoinPubToServer']=function() -- Join Server --> Network Server
      DataConverter.joinAcceptHandler(data.data)
    end,
    ['AppPubToServer']=function() -- Application Server ---> Network Server
    end,
    [utiles.Default]=function() p('data.type is error',data.type)end
  }
end
return {
  process=process,
}