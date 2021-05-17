-- const BluebirdPromise = require('bluebird');
-- const { consts, utils } = require('../lora-lib');
-- const MacCommandIssuers = require('../macCmdIssuers');

return function (devAddr, status, gwrx) 
  -- let _this = this;
  -- return new BluebirdPromise((resolve, reject) => {
    -- _this.log.debug({
    --   label: 'MAC Command Ans',
    --   message: {
    --     DeviceTimeReq: {
    --       Status: status,
    --     },
    --   },
    -- });
    p(
      {
        label= 'MAC Command Ans',
        message= {
          DeviceTimeReq= {
            Status= status,
          },
        },
      }
    )

    local time = Date.now() / 1000;
    local seconds = parseInt(time);
    local fractional_time = time - parseInt(time);
    local fractionalsec = parseInt(fractional_time * 256);
    local MacCommandIssuer = MacCommandIssuers[consts.DEVICETIME_CID].bind(_this, devAddr, seconds, fractionalsec);
    return MacCommandIssuer();

  --   resolve();
  -- });
end
