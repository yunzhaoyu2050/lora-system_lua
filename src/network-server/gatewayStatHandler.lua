-- 'use strict';

-- // const util = require('util');
-- const BluebirdPromise = require('bluebird');
-- const _ = require('lodash');
-- const Ajv = require('ajv');
-- const ajv = new Ajv({ allErrors: true });
-- const ERRROR = require('../lora-lib/ERROR');
-- let gatewayStatSchema = require('./schema/gatewaySate.schema.json');
-- ajv.addSchema(gatewayStatSchema, 'gatewayStatSchema');

-- function GatewayStatHandler(GatewayStatus) {
--   let _this = this;
--   _this.GatewayStatus = GatewayStatus;
-- }

function handle(GatewayStatObj) 
  -- let valid = ajv.validate('gatewayStatSchema', GatewayStatObj);
  -- if (!valid) {

  --   -- TODO:
  --   return BluebirdPromise.reject(
  --     new ERRROR.JsonSchemaError('GatewayState Schema : ' + ajv.errorsText()));
  -- end

  return 0
  -- // return _this.GatewayStatus.createItem(GatewayStatObj);
end

-- module.exports = GatewayStatHandler;

return {
  handle = handle
}
