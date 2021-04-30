local joinHandler = require("./joinHandler.lua")
function handleMessage(recvServerData,callBack)
  if recvServerData ~= nil then
    if recvServerData.rxpk ~= nil then 
      local acptPHYPayload = joinHandler.handler(recvServerData.rxpk)
      if acptPHYPayload ~= nil then
        recvServerData.rxpk.data = acptPHYPayload -- join server处理之后的数据
        return recvServerData
      end
    else
      p("recvServerData.rxpk is nil")
    end
  end
  return nil
end
return {
  handleMessage = handleMessage
}
