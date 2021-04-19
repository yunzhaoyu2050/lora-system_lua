## Controller

The LoRa network controller focuses on processing and managing MAC commands, which are used to modify associated conﬁgurations or adjust transmission parameters in physical layer. 

LoRa网络控制器专注于处理和管理MAC命令，这些命令用于修改关联的配置或调整物理层中的传输参数。

### Functions

The LoRa network controller implements the analysis of the uplink MAC Commands, performs corresponding algorithms, and generates the downlink MAC Commands which may be sent within the downlink packet or individually.  

LoRa网络控制器执行对上行链路MAC命令的分析，执行相应的算法，并生成可以在下行链路数据包内发送或单独发送的下行链路MAC命令。

#### MAC Command Queue

For each end-device, the LoRa network controller maintains a MAC Command queue with each element in the queue as shown in the following table.

对于每个终端设备，LoRa网络控制器维护一个MAC Command队列，队列中的每个元素都如下表所示。

|  Field  |              Description               |
| :-----: | :------------------------------------: |
|   CID   |             MAC Command ID             |
| Payload | Byte sequence that Command may contain |

#### MAC Command Alogorithm

The step one starts as soon as the uplink packet arrives, and step one to step nine is continuous cycling.

一旦上行链路数据包到达，第一步便开始，而第一步到九步是连续循环。

1. Once the uplink data arrives, if the packet contains the MAC Command, the LoRa Network Server extracts the part and sends it to the Network Controller by an array;
一旦上行链路数据到达，如果数据包包含MAC命令，则LoRa网络服务器将提取该部分并将其通过阵列(network-server->network-controller之间的消息队列)发送给网络控制器；
2. The LoRa Network Controller will read all the commands in the MAC Command Request Queue, and put them into the array Q, then traverse the array Q, then delete all data in the MAC Command Answer Queue;
LoRa网络控制器将读取MAC命令请求队列中的所有命令，并将它们放入数组Q中，然后遍历数组Q，然后删除MAC命令应答队列中的所有数据；
3. The MAC Command in the data packet which the Network Controller receives contains answers and requests, and the Network Controller will traverse all the data packet;
网络控制器接收到的数据包中的MAC命令包含应答和请求，网络控制器将遍历所有数据包；
4. When Encountering MAC Command answer, the Network Controller will compare it with the array Q, and record the position of the first unmatched answer-request pair as d;
当遇到MAC命令应答时，网络控制器会将其与数组Q进行比较，并将第一个unmatched的应答请求对的位置记录为d；
5. When Encountering MAC Command request, the Network Controller will process it;
当遇到“ MAC命令”请求时，网络控制器将对其进行处理。
6. Clear the original MAC Command Request Queue, and push all elements of array Q from position d into the new MAC Command Request Queue;
清除原始的MAC命令请求队列，并将数组Q中所有元素从位置d推入新的MAC命令请求队列；
7. Traverse MAC Command Request Queue and application data Queue;
遍历MAC命令请求队列和应用程序数据队列；
8. Construct downlink data according to the following table policy and send it to the Network Connector by Network Server;
根据下表策略构造下行链路数据，然后通过网络服务器将其发送到网络连接器；
9. The Network Connector encapsulates the LoRa packet and delivers it to the gateway.
网络连接器封装LoRa数据包并将其传递到网关。

<center>Downlink MAC Command and Application Data Group Package Policy</center>

| Downlink Application Data |   Downlink MAC Commands    | Send Downlink Packet | FOpts |    FRMPayload    |           Other            |
| :-----------------------: | :------------------------: | :------------------: | :---: | :--------------: | :------------------------: |
|       Not Available       |       Not Available        |          No          |   -   |        -         |             -              |
|       Is Available        |       Not Available        |         Yes          | Null  | Application Data |             -              |
|       Not Available       | Is Available (> 15 bytes)  |         Yes          | Null  |       MAC        |         FPort = 0          |
|       Not Available       | Is Available (<= 15 bytes) |         Yes          |  MAC  |       Null       |             -              |
|       Is Available        | Is Available (> 15 bytes)  |         Yes          | Null  |       MAC        | FPort = 0</br>FPending = 1 |
|       Is Available        | Is Available (<= 15 bytes) |         Yes          | Null  | Application Data |             -              |

### Interaction with LoRa Nework Server

The LoRa join server subscribes the topic CS-sub to receive join requests from LoRa network server, and publishes join accept on topic CS-pub to LoRa network server.

LoRa加入服务器订阅主题CS-sub以从LoRa网络服务器接收加入请求，并将主题CS-pub上的加入接受发布到LoRa网络服务器。

* **Network Server to Network Controller**

```json
   {
       DevAddr: <Buffer 00 96 44 72>,
       data: [
       {
        	0x01: { Version: <Buffer 02>, },
       },
   	  {
       	0x02: null,
       },
       {
       	0x03: { "Status": <Buffer 02>, },
       },
   	],
       adr: true,
       devtx:
         {
           "freq": 433.3,
           "datr": "SF7BW125",
           "codr": "4/6",
         },
       gwrx: [
         {
           gatewayId: <Buffer b8 27 eb ff fe 52 0e 51>,
           time: "2013-03-31T16:21:17.528002Z",
           tmst: 3512348611,
           chan: 2,
           rfch: 0,
           stat: 1,
           modu: "LORA",
           rssi: -35,
           lsnr: 5.1,
           size: 32,
         },
       ],
     }
```

* **Network Controller to Network Server**

```json
    {
       "cid": "payload",
     }
   
```
*Example:* 

```json
    {
       0x01: { "Version": <Buffer 02>, },
    }
```

---