# lora-system_lua
lora-system realized by lua

### File and folder description:

1、config/config.json 服务器配置文件

2、data/  存放数据库文件

3、deps/  依赖的三方件

4、docs/  ___框架说明文档___ design by https://github.com/xisiot/lora-system

5、src/ lua文件

6、test/ 测试需要的文件

7、test/emulator.sh 模拟节点数据启动脚本

8、test/lora-motes-emulator/ 模拟节点程序源码及配置文件 design by https://github.com/xisiot/lora-motes-emulator

9、utiles/  公用代码

### lorawan system framework 

design by https://github.com/xisiot/lora-system

1、[index.md](/docs/index.md)

2、[Tutorials Application Integration.md](/docs/Tutorials/Application-Integration.md)

3、[Tutorials Configuration.md](/docs/Tutorials/Configuration.md)

4、[Tutorials Installation.md](/docs/Tutorials/Installation.md)

5、[Tutorials Installation-of-LoRa-Web-Server.md](/docs/Tutorials/Installation-of-LoRa-Web-Server.md)

6、[Tutorials Usage.md](/docs/Tutorials/Usage.md)

7、[Implementations Connector.md](/docs/Implementations/Connector.md)

8、[Implementations Controller.md](/docs/Implementations/Controller.md)

9、[Implementations Join.md](/docs/Implementations/Join.md)

10、[Implementations Motes.md](/docs/Implementations/Motes.md)

11、[Implementations Server.md](/docs/Implementations/Server.md)

### usage：
    构建所需要的依赖文件
    make

    启动模拟设备节点测试程序, join: 入网请求消息， app: 应用消息 !!舍弃
    ./emulator.sh join !!舍弃

    启动lorawan server测试程序， test：指代测试模式，会重新覆盖原始数据库数据
    ./run test/test.lua test 

### database
#### RedisModels:   内存中存储

~~1、DeDuplication.lua~~

2、DeviceInfo.lua,  key: DevAddr

```	
    "DevAddr",  新增
    "frequencyPlan",
    "RX1DRoffset",
    "RX1Delay",
    "FCntUp",
    "NFCntDown",
    "AFCntDown",
    "tmst",
    "rfch",
    "powe",
    "freq",
    "ADR",
    "imme",
    "ipol"
```

~~3、DevRXInfoQueue.lua~~

~~4、DownlinkCmdQueue.lua~~

5、GatewayInfo.lua, key: gatewayId

```
    "gatewayId",  新增
    "pullPort",
    "pushPort",
    "version",
    "address",
    "userID"
```

~~6、MacCmdQueue.lua~~

~~7、MessageQueue.lua~~

#### MySQLModels:   内存与文件中共存，定时会同步到文件中

1、AppInfo.lua, key:AppEUI, file:AppInfo.data

```
    memory:
    "AppEUI",
    "userID",
    "name"
```

2、DeviceConfig.lua, key: DevAddr, file:DeviceConfig.data

```
    memory:
    "DevAddr",
    "frequencyPlan",
    "ADR",
    "ADR_ACK_LIMIT",
    "ADR_ACK_DELAY",
    "ChMask",
    "CFList",
    "ChDrRange",
    "RX1CFList",
    "RX1DRoffset",
    "RX1Delay",
    "RX2Freq",
    "RX2DataRate",
    "NbTrans",
    "MaxDCycle",
    "MaxEIRP"
```

4、DeviceInfo.lua, key: DevAddr, file:DeviceInfo.data

```
    memory:
    "DevEUI",
    "DevAddr",
    "AppKey"
    "AppEUI",
    "DevNonce",
    "AppNonce",
    "NwkSKey",
    "AppSKey",
    "activationMode",
    "ProtocolVersion",
    "FCntUp",
    "NFCntDown",
    "AFCntDown"
```

5、DeviceRouting.lua, key: DevAddr, file:DeviceRouting.data

```
    memory:
    " DevAddr",
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
```

~~6、DeviceStatus.js~~

7、GatewayInfo.lua, key: gatewayId, file:GatewayInfo.data

```
    memory:
    "gatewayId",
    "userID",
    "frequencyPlan",
    "location",
    "RFChain",
    "type",
    "model"
```

~~8、GatewayStatus.js~~
