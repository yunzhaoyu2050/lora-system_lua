-- local queue = require("../../../../deps/Dee_LuaADT/queue.lua")
-- -- 'use strict';

-- -- const BluebirdPromise = require('bluebird');
-- -- const utils = require('../../utils');

-- -- function DevRXInfoQueue(redis) {
-- --   this._ioredis = redis;
-- -- }

-- local DevRXInfoQueueTbl = {} -- 以devaddr作为key

-- local DevRXInfoQueue = {}

-- function DevRXInfoQueue.checkQueueLength(devaddr, mq)
--   return #DevRXInfoQueueTbl[devaddr]
-- end

-- function DevRXInfoQueue.consumeAllData(devaddr, mq)

--   -- let _this = this;
--   -- return _this._ioredis.lrange(mq, 0, -1).then((res) => {
--   --   let queueArr = res;
--   --   queueArr.forEach((element, index) => {
--   --     try {
--   --       element = JSON.parse(element);
--   --     }
--   --     catch (error) {
--   --       element = element;
--   --     }
--   --   });
--   --   return _this._ioredis.del(mq).then((res) => BluebirdPromise.resolve(queueArr));
--   -- });
--   for i=1,#DevRXInfoQueueTbl[devaddr] do
    
--   end
-- end

-- DevRXInfoQueue.prototype.consume = function (mq) {

--   let _this = this;
--   return _this._ioredis.lpop(mq).then(function (res) {
--     return BluebirdPromise.resolve(!res ? res : JSON.parse(res));
--   });
-- };

-- DevRXInfoQueue.prototype.produce = function (mq, src) {

--   let _this = this;

--   if (!utils.isObject(src)) {
--     return BluebirdPromise.reject(new Error('src should be an object'));
--   }

--   return _this._ioredis.rpush(mq, JSON.stringify(src))
--     .then(function (res) {
--       if (res = 1) {
--         return BluebirdPromise.resolve(true);
--       }
--       else if (res > 1) {
--         return BluebirdPromise.resolve(false);
--       }
--       return BluebirdPromise.reject(new Error('DevRXInfoQueue Push failed.'));
--     });
-- };

-- -- module.exports = DevRXInfoQueue;
