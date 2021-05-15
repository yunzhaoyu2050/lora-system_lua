-- #!/usr/bin/env node
local processFlow = require("./processFlow.lua")
-- const config = require('../config');
-- const bluebird = require('bluebird');
-- const DbClient = require('../lib/lora-lib/dbClient');
-- const DbModels = require('../models');
-- const loraLib = require('../lib/lora-lib');
-- const { ERROR, Log, MQClient } = loraLib;
-- const ProcessFlow = require('../lib/processFlow');

-- const dbModels = new DbModels(DbClient);
-- const redisConn = dbModels.redisConn;
-- const mysqlConn = dbModels.mysqlConn;
-- const log = new Log(config.log);
-- const mqClient = new MQClient(config.mqClient_nct, log);
-- const processFlow = new ProcessFlow(mysqlConn, redisConn, log);

-- function ErrorHandler(error) {
--   if (error instanceof ERROR.MsgTypeError) {
--     log.error(error.stack);
--   } else if (error instanceof ERROR.JsonSchemaError) {
--     log.error(error.stack);
--   } else if (error instanceof ERROR.DeviceNotExistError) {
--     log.error(error.stack);
--   } else {
--     log.error(error.stack);
--   }
-- }

-- mqClient.connect()
--   .then(() => {
--     mqClient.message((message) => {
--       const messageTopic = message.topic;

--       if (messageTopic === config.mqClient_nct.topics.subFromServer) {
--         log.debug({
--           label: `Msg from ${messageTopic}`,
--           message: message,
--         });

--         let messageObj = message.value;
--         if (messageObj.adr == false && messageObj.data.length == 0) {
--           return bluebird.reject(new Error(`"data" fields should not be empty when adr is true`));
--         }

--         return processFlow.process(messageObj)
--           .catch((err) => {
--             log.error(err);
--           });
--       }

--       return bluebird.reject(new Error(`Error topic "${message.topic}", Message "${message}"`));
--     });

--     log.debug('Listening on Kafka topic : ' + config.mqClient_nct.consumerGroup.topics);
--     return bluebird.resolve();
--   })
--   .catch(error => {
--     log.error(error.stack);
--     bluebird.all([
--       dbModels.close(),
--       mqClient.disconnect(),
--     ]);
--   });
function _process(recvData)
  if recvData ~= nil then
    return processFlow.process(recvData)
  end
end
return {
  Process = _process
}