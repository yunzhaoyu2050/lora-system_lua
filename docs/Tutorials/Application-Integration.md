## Application Integration

#### Introduction

This section describes how to integrate customized application servers into X-LoRa systems.<br>
Application Server is responsible for handling application payloads. It is necessary to support various applications with different encoding methods such as Protocol Buffer serialization to improve network transmission efficiency. Application Server also functions as a bridge between the cloud platform owned by users and the X-LoRa system so that customers can control LoRa devices and enjoy the applications through web browsers or APPs on smartphones. The IoT cloud can get the application payloads by subscribing the specific topic, and can also send downlink messages to the LoRa Server through the application server.

本节介绍如何将自定义的应用程序服务器集成到X-LoRa系统中。<br>
Application Server负责处理应用程序有效负载。 必须使用诸如协议缓冲区序列化之类的不同编码方法来支持各种应用程序，以提高网络传输效率。 Application Server还充当用户拥有的云平台与X-LoRa系统之间的桥梁，以便客户可以控制LoRa设备并通过Web浏览器或智能手机上的APP欣赏应用程序。 IoT云可以通过订阅特定主题来获取应用程序负载，还可以通过应用程序服务器向LoRa服务器发送下行链路消息。

#### Interaction with Server

The data exchange format from Server to Application Server is defined in this section.

本节中定义了从服务器到应用程序服务器的数据交换格式。

##### Server to Application Server

```json
{
    DevAddr: <Buffer 00 08 fb 31>,
    FRMPayload: <Buffer c9 77 36 15>,
}
```

##### Application Server to Server

```json
{
    DevAddr: <Buffer 00 08 fb 31>,
    FRMPayload: <Buffer ff 01 ff>,
}
```
---