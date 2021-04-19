## Usage

This section describes the detailed instructions of X-LoRa. It shows how to create applications, register gateways and activate devices.

本节介绍X-LoRa的详细说明。 它显示了如何创建应用程序，注册网关和激活设备。

#### Registration on LoRa Web

Users need to register their applications, gateways and devices on the LoRa web before further operations.

用户需要在LoRa Web上注册其应用程序，网关和设备，然后才能进行进一步操作。

##### User Management

Create an account for the LoRa web and start enjoying the service the LoRa server provided. With a LoRa web account, the following can be done:

为LoRa网络创建一个帐户，然后开始使用LoRa服务器提供的服务。 使用LoRa网络帐户，可以执行以下操作：

* Creating applications, gateways and devices
* Easy access to the transmission data and application data

* 创建应用程序，网关和设备
* 轻松访问传输数据和应用程序数据

It's necessary to fill in the following fields when register an account. Note that the password field requires at least 6 characters long.

注册帐户时，必须填写以下字段。 请注意，密码字段至少需要6个字符。

<center>TABLE 1 Description of User Registration Form</center>

|     Field      |  Type  |   Description   | Attribute |
| :------------: | :----: | :-------------: | :-------: |
|      Name      | String |   User's name   | Required  |
| E-mail Address | String |  User's email   | Required  |
|    Password    | String | User's password | Required  |

##### Gateway Management

LoRa gateways directly connect to LoRa network connector and upload and download data for LoRa devices. However, registering gateway in the LoRa web is firstly needed. The verification of the existence of the gateways without registering in the LoRa web can’t success.

LoRa网关直接连接到LoRa网络连接器，并上传和下载LoRa设备的数据。 但是，首先需要在LoRa网站中注册网关。 没有在LoRa网络中注册就无法验证网关的存在。

The fields in the following table need to be filled in during the registration of gateways. Note that the gatewayID field should be unique. If not, the registration can’t be successful.

下表中的字段需要在网关注册期间填写。 请注意，gatewayID字段应该是唯一的。 否则，注册将无法成功。

Once the registration is successful, the web will return a list of gateways that the user has registered.

一旦注册成功，Web将返回用户已注册的网关列表。

<center>TABLE 2 Description of Gateway Registration Form</center>

|     Field      |  Type  |     Description     | Attribute |
| :------------: | :----: | :-----------------: | :-------: |
|   gatewayID    | String | Gateway MAC address |  Unique   |
|      type      | String |   Indoor/Outdoor    | Required  |
| frequency plan | Number |      Frequency      | Required  |
|     model      | String |     X01/X02/X03     | Required  |
|    location    | String |  Gateway location   | Required  |

##### Application Management

Each device belongs to a certain application. Therefore, before registering devices, users should register applications first.

每个设备都属于某个应用程序。 因此，在注册设备之前，用户应首先注册应用程序。

The fields in the following table need to be filled in during the registration of applications. Note that the AppEUI field should be unique. If not, the registration can’t be successful.

下表中的字段需要在注册申请时填写。 请注意，AppEUI字段应该是唯一的。 否则，注册将无法成功。

Once the registration is successful, the web will return a list of applications that the user has registered.

注册成功后，网络将返回用户已注册的应用程序列表。

<center>TABLE 3 Description of Application Registration Form</center>

|      Field       |  Type  |            Description             | Attribute |
| :--------------: | :----: | :--------------------------------: | :-------: |
| Application Name | String |          Application name          | Required  |
|      AppEUI      | String | LoRa™ application unique identifier |  Unique   |

##### Device Management

Before LoRa devices are able to connect to the LoRa server, users should register them in the LoRa web. Without that, the verification of the existence of the devices will fail.

在LoRa设备能够连接到LoRa服务器之前，用户应在LoRa网络中注册它们。 否则，将无法验证设备的存在。

Device registration must be performed after the application is registered, which has been explained in the previous section. Due to the fact that activation of an end-device can be achieved in two ways, device registration can be divided into two categories, i.e., Over-The-Air Activation (OTAA) and Activation by Personalization (ABP) modes. The attribute fields required for the registration of the two modes have different requirements, i.e.,

设备注册必须在注册应用程序后执行，这已在上一节中进行了说明。 由于可以通过两种方式来实现终端设备的激活，因此设备注册可以分为两类，即空中激活（OTAA）模式和个性化激活（ABP）模式。 两种模式的注册所需的属性字段有不同的要求，即

* OTAA Mode

  The fields in the following table need to be filled in during the registration of devices. Note that the DevEUI field should be unique. If not, the registration can’t be successful.

  下表中的字段需要在设备注册期间填写。 请注意，DevEUI字段应该是唯一的。 否则，注册将无法成功。

  Once the registration is successful, the web will return a list of devices that the user has registered.

  注册成功后，网络将返回用户已注册的设备列表。

  <center>TABLE 4 Description of OTAA Device Registration Form</center>

  | Field  |  Type  |          Description          | Attribute |
  | :----: | :----: | :---------------------------: | :-------: |
  | DevEUI | String | LoRa device unique identifier |  Unique   |
  | AppKey | String |    AES-128 application key    | Required  |

* ABP Mode

  The fields in the following table need to be filled in during the registration of devices. Note that the DevEUI field and DevAddr field should be unique. If not, the registration can’t be successful.

  下表中的字段需要在设备注册期间填写。 请注意，DevEUI字段和DevAddr字段应该是唯一的。 否则，注册将无法成功。

  Once the registration is successful, the web will return a list of devices that the user has registered.

  注册成功后，网络将返回用户已注册的设备列表。

  <center>TABLE 5 Description of ABP Device Registration Form</center>

  |  Field  |  Type  |          Description          | Attribute |
  | :-----: | :----: | :---------------------------: | :-------: |
  | DevEUI  | String | LoRa device unique identifier |  Unique   |
  | AppKey  | String |    AES-128 application key    | Required  |
  | DevAddr | String |  LoRa device unique address   |  Unique   |
  | NwkSKey | String |      Network session key      | Required  |
  | AppSKey | String |    Application session key    | Required  |

#### Interaction with LoRa Server
For over-the-air activation, LoRa devices must follow a join procedure prior to participating in data exchanges with the Network Server. An end-device has to go through a new join procedure every time when it has lost the session context information. After that, devices can send the uplink messages and receive the downlink messages from the LoRa server.

对于无线激活，LoRa设备在参与与网络服务器的数据交换之前必须遵循加入程序。 终端设备每次丢失会话上下文信息时，都必须经历新的加入过程。 之后，设备可以从LoRa服务器发送上行消息并接收下行消息。

Activating a LoRa devices by personalization means that all the necessary information is stored in devices in the very beginning. These devices can interact with LoRa server directly.

通过个性化激活LoRa设备意味着一开始就将所有必要的信息存储在设备中。 这些设备可以直接与LoRa服务器交互。

---