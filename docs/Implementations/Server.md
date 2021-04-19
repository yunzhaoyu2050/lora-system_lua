## Server

The LoRa network server is the core of the whole X-LoRa system.

LoRa网络服务器是整个X-LoRa系统的核心。

### Functions

* **Data Managemrnt and Service Scheduling 数据管理和服务调度**

Server is responsible for data management and service scheduling. It invokes different modules according to the requirements of data processing. Depending on the type of uplink packet, the information in the packet is separated into specific formats. 

服务器负责数据管理和服务调度。 它根据数据处理的要求调用不同的模块。 根据上行链路分组的类型，分组中的信息被分成特定的格式。

The data about MAC layer control commands is sent to Controller, the original application data is fed into Application Server and the join packets are forwarded to the Join Server without any interpretation. 

有关MAC层控制命令的数据将发送到Controller，原始应用程序数据将被馈送到Application Server中，并且连接数据包将不做任何解释地转发到Join Server。

Moreover, Server is required to schedule packet transmissions on the downlink. One of LoRa gateways is selected to send downlink packets through exploiting the uplink transmission parameters such as RSSI and SNR. 

此外，要求服务器在下行链路上调度数据包传输。 选择一个LoRa网关以通过利用上行传输参数（例如RSSI和SNR）发送下行数据包。

In addition, Server identifies the contents of downlink packets from two queues, which are responsible for application data and MAC commands.

另外，服务器从两个队列中识别下行链路数据包的内容，这两个队列负责应用程序数据和MAC命令。

* **Deduplication 重复数据删除**

Sometimes, LoRa devices may connect with more than one LoRa gateway. Therefore, single packet from a LoRa device is likely to be received by multiple LoRa gateways simultaneously. To avoid the waste of radio resources due to redundancy, Server is essential for filtering duplicate packets. Only one of the duplicate packets is fed into the subsequent processing modules such as Application Server and Controller. However, the transmission information such as SNR attached in the duplicate packets is not discarded and can be used as reference parameters for downlink routing. Finally, historical data is collected and stored in Server. It can provide the possibility for managers to check up the uplink/downlink packets and monitor the running states of LoRa devices and gateways.

有时，LoRa设备可能会与多个LoRa网关连接。 因此，来自LoRa设备的单个数据包很可能会同时被多个LoRa网关接收。 为了避免由于冗余而浪费无线电资源，服务器对于过滤重复的数据包至关重要。 仅重复的数据包之一被送入后续处理模块，例如Application Server和Controller。 但是，重复信息包中附加的诸如SNR之类的传输信息不会被丢弃，并且可以用作下行链路路由的参考参数。 最后，历史数据被收集并存储在服务器中。 它可以为管理人员提供检查上行/下行数据包并监视LoRa设备和网关的运行状态的可能性。

### HTTP APIs

The HTTP APIs are used to register and issue downlink MAC Commands. It is convenient for users to manage the system. Furthermore, users can integrate X-LoRa into their own platforms using these HTTP APIs. All HTTP API methods are listed below.

#### User Register

Only users who have been registered can use the X-LoRa System. This API is used for user register and returns the userID used for gateway, application and device register.

```javascript
POST /register
```

* Request
```json
Headers:
  Content-Type: application/x-www-form-urlencoded

Body:
  {
    "email": "test@xisiot.com",
    "password": "123456"
  }
```

* Response
```json
Body:
  {
    "userID": "4c0c99ca5caef7c9f4707d641c726f55"
  }
```
#### User Login

This API is used for user login and returns the userID.

``` javascript
POST /login
```

* Request
```json
Headers:
  Content-Type: application/x-www-form-urlencoded

Body:
  {
    "email": "test@xisiot.com",
    "password": "123456"
  }
```

* Response
```json
Body:
  {
    "userID": "4c0c99ca5caef7c9f4707d641c726f55"
  }
```
#### Application Register 

This API is used for application register.

``` javascript
POST /application
```

* Request
```json
Headers:
  Content-Type: application/x-www-form-urlencoded

Body:
  {
    "userID": "4c0c99ca5caef7c9f4707d641c726f55",
    "AppEUI": "9816be466f467a17",
    "name": "test"
  }
```

* Response
```json
Body:
  {
    "code": "200",
    "message": "success"
  }
```
#### Device Register

This API is used for device register.

``` javascript
POST /device
```

* Request
```json
Headers:
  Content-Type: application/x-www-form-urlencoded

Body:
  {
    "AppEUI": "9816be466f467a17",
    "DevEUI": "AAAAAAAAAAAAAAAA",
    "AppKey": "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
  }
```

* Response
```json
Body:
  {
    "code": "200",
    "message": "success"
  }
```
#### Gateway Register

This API is used for gateway register.

``` javascript
POST /gateway
```

* Request
```json
Headers:
  Content-Type: application/x-www-form-urlencoded

Body:
  {
    "userID": "4c0c99ca5caef7c9f4707d641c726f55",
    "gatewayId": "bbbbbbbbbbbbbbbb"
  }
```

* Response
```json
Body:
  {
    "code": "200",
    "message": "success"
  }
```
#### Issue MAC Commands

This API is used to send the downlink MACCommand.

此API用于发送下行链路MACCommand。

``` javascript
POST /maccommand
```

* Request
```json
Headers:
  Content-Type: application/x-www-form-urlencoded

Body:
  {
    "DevAddr": "12345678",
    "MACCommand": "030200ff01"
  }
```

* Response
```json
Body:
  {
    "code": "200",
    "message": "success"
  }
```
* MAC Commands

  All the MAC Commands defined in LoRaWAN™ 1.1 are listed below. Bold font means the downlink MAC Commands.

  下面列出了LoRaWAN™1.1中定义的所有MAC命令。 粗体字表示下行链路MAC命令。

  | Cid  |       MAC Command       |                   Payload                   |      Length(byte)       |
  | :--: | :---------------------: | :-----------------------------------------: | :---------------------: |
  | 0x01 |        ResetInd         |                   Version                   |            1            |
  | 0x01 |      **ResetConf**      |                 **Version**                 |          **1**          |
  | 0x02 |      LinkCheckReq       |                                             |            0            |
  | 0x02 |    **LinkCheckAns**     |          **Margin**<br> **GwCnt**           |     **1**<br>**1**      |
  | 0x03 |     **LinkADRReq**      | **TXPower**<br>**ChMask**<br>**Redundancy** | **1**<br>**2**<br>**1** |
  | 0x03 |       LinkADRAns        |                   Status                    |            1            |
  | 0x04 |    **DutyCycleReq**     |               **DutyCyclePL**               |          **1**          |
  | 0x04 |      DutyCycleAns       |                                             |            0            |
  | 0x05 |   **RXParamSetupReq**   |       **DLSettings**<br>**Frequency**       |     **1**<br>**3**      |
  | 0x05 |     RXParamSetupAns     |                   Status                    |            1            |
  | 0x06 |    **DevStatusReq**     |                                             |          **0**          |
  | 0x06 |      DevStatusAns       |              Battery<br>Margin              |         1<br>1          |
  | 0x07 |    **NewChannelReq**    |   **ChIndex**<br>**Freq**<br>**DrRange**    | **1**<br>**3**<br>**1** |
  | 0x07 |      NewChannelAns      |                   Status                    |            1            |
  | 0x08 |  **RXTimingSetupReq**   |                **Settings**                 |          **1**          |
  | 0x08 |    RXTimingSetupAns     |                                             |            0            |
  | 0x09 |   **TxParamSetupReq**   |                **DwellTime**                |          **1**          |
  | 0x09 |     TxParamSetupAns     |                                             |            0            |
  | 0x0A |    **DlChannelReq**     |           **ChIndex**<br>**Freq**           |     **1**<br>**3**      |
  | 0x0A |      DlChannelAns       |                   Status                    |            1            |
  | 0x0B |        RekeyInd         |                   Version                   |            1            |
  | 0x0B |      **RekeyConf**      |                 **Version**                 |          **1**          |
  | 0x0C |  **ADRParamSetupReq**   |                **ADRParam**                 |          **1**          |
  | 0x0C |    ADRParamSetupAns     |                                             |            0            |
  | 0x0D |      DeviceTimeReq      |                                             |            0            |
  | 0x0D |    **DeviceTimeAns**    |      **Seconds**<br>**FractionalSec**       |     **4**<br>**1**      |
  | 0x0E |   **ForceRejoinReq**    |             **ForceRejoinReq**              |          **2**          |
  | 0x0F | **RejoinParamSetupReq** |           **RejoinParamSetupReq**           |          **1**          |
  | 0x0F |   RejoinParamSetupAns   |                   Status                    |            1            |

#### Issue Downlink Application Data
This API is used to send the downlink application data.

此API用于发送下行链路应用程序数据。

``` javascript
POST /downlink
```

* Request
```json
Headers:
  Content-Type: application/x-www-form-urlencoded

Body:
  {
    "DevAddr": "12345678",
    "Downlink": "ff01ff"
  }
```

* Response
```json
Body:
  {
    "code": "200",
    "message": "success"
  }
```

#### Error List

| Code |           Message           |
| :--: | :-------------------------: |
| 2101 |        invalid email        |
| 2102 |      invalid password       |
| 2103 |       invalid AppEUI        |
| 2104 |       invalid DevEUI        |
| 2105 |       invalid AppKey        |
| 2106 |      invalid gatewayId      |
| 2107 |       invalid DevAddr       |
| 2108 |     invalid MACCommand      |
| 2109 |     invalid Downlink        |
| 3101 |   user already registered   |
| 3102 |     user not registered     |
| 3103 |     user password error     |
| 3104 |       userID required       |
| 3105 |        email required       |
| 3106 |      password required      |
| 3107 |        AppEUI required      |
| 3108 |         name required       |
| 3109 |        DevEUI required      |
| 3110 |       AppKey required       |
| 3111 |      gatewayId required     |
| 3112 |       DevAddr required      |
| 3113 |     MACCommand required     |
| 3114 |       Downlink required     |
| 3201 | application already created |
| 3202 |   application not created   |
| 3301 |   device already created    |
| 3401 |   gateway already created   |

---