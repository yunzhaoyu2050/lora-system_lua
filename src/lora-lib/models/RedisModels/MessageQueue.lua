local queue = require("../../../../deps/Dee_LuaADT/queue.lua")

local MessageQueueTbl = {}
local MessageQueue = {}

function MessageQueue.consume(devaddr) -- 出队
  return MessageQueueTbl[devaddr].dequeue()
end

function MessageQueue.checkQueueLength(devaddr) -- 获取长度
  return #MessageQueueTbl[devaddr]
end

function MessageQueue.produce(devaddr, src, protoBufUnit, AppEUI) -- 入队
  -- let _this = this;

  -- if (!utils.isObject(src) || utils.isEmptyValue(src.data)) {
  --   return BluebirdPromise.reject(
  --     new Error(JSON.stringify({
  --       message: 'MessageQueue Input src should be an object && Contains keyword \'data\'',
  --       AppEUI: AppEUI,
  --       scr: src,
  --     })));
  -- }

  -- return _this.consume(mq).then(function (des) {
  --   if (!des) {
  --     des = src;
  --     des.aggregation = 0;
  --   } else {
  --     des = utils.mergeObjDeeply(des, src);
  --     des.aggregation++;
  --   }

  --   return protoBufUnit.JSONToPBUnit(des.data, AppEUI)
  --     .then(function (res) {
  --       if (!Buffer.isBuffer(res) && typeof res === 'object') {
  --         return BluebirdPromise.reject(new Error(JSON.stringify({
  --           message: 'Revice Object Data and No PB Config',
  --           AppEUI: AppEUI,
  --           data: des.data,
  --         })));
  --       }

  --       let pbBufStr = res.toString('hex');
  --       des.pbdata = pbBufStr;

  --       return _this._ioredis.rpush(mq, JSON.stringify(des));
  --     });
  -- }).then(function (res) {
  --   if (res > 0) {
  --     return BluebirdPromise.resolve(true);
  --   }

  --   return BluebirdPromise.reject(new Error('push failed.'));
  -- });
  if MessageQueueTbl[devaddr] == nil then
    MessageQueueTbl[devaddr] = queue.create()
  end
  return MessageQueueTbl[devaddr].enqueue(src)
end

-- MessageQueue.prototype.produceByHTTP = function (mq, downlinkString) {
--   let _this = this;
--   const writeObj = {
--     pbdata: null,
--     data: null,
--     aggregation: null,
--   };
--   writeObj.pbdata = downlinkString;
--   writeObj.data = downlinkString;
--   writeObj.aggregation = 0;
--   return _this._ioredis.rpush(mq, JSON.stringify(writeObj));
-- }
-- module.exports = MessageQueue;
return MessageQueue
