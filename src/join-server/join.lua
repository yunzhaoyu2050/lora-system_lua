-- local mqHandle = require('../src/common/message_queue.lua')
-- local timer = require("timer")
local joinHandler = require('./joinHandler.lua')
function handleMessage(recvServerData)
  -- local recvServerData = mqHandle.Subscription('ServerPubToJoin')
  if recvServerData ~= nil then
    if recvServerData.rxpk ~= nil then
      local acptPHYPayload = joinHandler.handler(recvServerData.rxpk)
      -- .then((acptPHYPayload) => {
        recvServerData.rxpk.data = acptPHYPayload
      --   return mqClient.publish(config.mqClient_js.producer.joinServerTopic, message.value);
      -- })
      return recvServerData.rxpk.data
    else
      p('recvServerData.rxpk is nil')
    end
  end
end
-- function _init()
--   timer.setInterval(1000, function()
--     handleMessage()
--   end)
-- end
-- return {
--   Init=_init,
-- }
return {
  handleMessage=handleMessage
}