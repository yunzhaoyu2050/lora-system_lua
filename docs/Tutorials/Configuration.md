## Configuration

The default configuration file is shown as follows.

```sh
{
  "database": {
    "mysql": {
      "username": "username",
      "password": "password",
      "database": "mysql",
      "host": "localhost",
      "port": 3306,
      "dialect": "mysql",
      "operatorsAliases": false,
      "logging": false,
      "timezone": "+08:00",
      "define": {
        "freezeTableName": true,
        "timestamp": true,
        "charset": "utf8"
      },
      "pool": {
        "max": 10,
        "min": 1,
        "idle": 10000,
        "acquire": 30000
      }
    },
    "redis": {
      "cluster": false,
      "options": [
        {
          "host": "localhost",
          "port": 6379
        }
      ]
    },
    "mongodb": {
      "host": "localhost",
      "port": 27017,
      "db": "loraLogger",
      "cluster": false
    }
  },
  "mqClient_ns": {
    "consumerGroup": {
      "options": {
        "kafkaHost": "localhost:9092",
        "groupId": "lora-network-server-message-dispatch-in",
        "sessionTimeout": 15000,
        "protocol": [
          "roundrobin"
        ],
        "fromOffset": "latest"
      },
      "topics": [
        "NS-sub",
        "AS-pub",
        "JS-pub"
      ]
    },
    "client": {
      "kafkaHost": "localhost:9092",
      "clientId": "lora-network-server-message-dispatch-out"
    },
    "producer": {
      "requireAcks": 1,
      "ackTimeoutMs": 100,
      "partitionerType": 2
    },
    "schemaPath": {
      "messages": "config/messages.json",
      "common": "config/common.json"
    },
    "topics": {
      "pubToApplicationServer": "AS-sub",
      "subFromApplicationServer": "AS-pub",
      "pubToConnector": "NC-sub",
      "subFromConnector": "NS-sub",
      "pubToJoinServer": "JS-sub",
      "subFromJoinServer": "JS-pub",
      "pubToControllerServer": "CS-sub",
      "subFromControllerServer": "CS-pub"
    }
  },
  "log": {
    "level": "debug",
    "colorize": true
  },
  "server": {
    "fcntCheckEnable": true,
    "deduplication_Delay": 200,
    "downlink_Data_Delay": 200
  },
  "mqClient_js": {
    "consumerGroup": {
      "options": {
        "kafkaHost": "localhost:9092",
        "groupId": "lora-join-server-consumer",
        "sessionTimeout": 15000,
        "protocol": [
          "roundrobin"
        ],
        "fromOffset": "latest"
      },
      "topics": [
        "JS-sub"
      ]
    },
    "client": {
      "kafkaHost": "localhost:9092",
      "clientId": "lora-join-server-produce"
    },
    "producer": {
      "requireAcks": 1,
      "ackTimeoutMs": 100,
      "partitionerType": 2,
      "joinServerTopic": "JS-pub"
    }
  },
  "mqClient_nc": {
    "consumerGroup": {
      "options": {
        "kafkaHost": "localhost:9092",
        "groupId": "lora-network-connector-consumer",
        "sessionTimeout": 15000,
        "protocol": [
          "roundrobin"
        ],
        "fromOffset": "latest"
      },
      "topics": [
        "NC-sub"
      ]
    },
    "client": {
      "kafkaHost": "localhost:9092",
      "clientId": "lora-network-connector-produce"
    },
    "producer": {
      "requireAcks": 1,
      "ackTimeoutMs": 100,
      "partitionerType": 2
    },
    "topics": {
      "pubToServer": "NS-sub"
    }
  },
  "udp": {
    "port": 1700
  },
  "http": {
    "port": 3000
  },
  "mqClient_as": {
    "consumerGroup": {
      "options": {
        "kafkaHost": "localhost:9092",
        "groupId": "lora-application-server-message-dispatch-in",
        "sessionTimeout": 15000,
        "protocol": [
          "roundrobin"
        ],
        "fromOffset": "latest"
      },
      "topics": [
        "AS-sub",
        "cloud-sub"
      ]
    },
    "client": {
      "kafkaHost": "localhost:9092",
      "clientId": "lora-application-server-message-dispatch-out"
    },
    "producer": {
      "requireAcks": 1,
      "ackTimeoutMs": 100,
      "partitionerType": 2
    },
    "schemaPath": {
      "messages": "config/messages.json",
      "common": "config/common.json"
    },
    "topics": {
      "pubToCloud": "cloud-pub",
      "subFromCloud": "cloud-sub",
      "pubToServer": "AS-pub",
      "subFromServer": "AS-sub"
    }
  },
  "mqClient_nct": {
    "consumerGroup": {
      "options": {
        "kafkaHost": "localhost:9092",
        "groupId": "lora-network-controller-message-dispatch-in",
        "sessionTimeout": 15000,
        "protocol": [
          "roundrobin"
        ],
        "fromOffset": "latest"
      },
      "topics": [
        "CS-sub"
      ]
    },
    "client": {
      "kafkaHost": "localhost:9092",
      "clientId": "lora-network-controller-message-dispatch-out"
    },
    "producer": {
      "requireAcks": 1,
      "ackTimeoutMs": 100,
      "partitionerType": 2
    },
    "schemaPath": {
      "messages": "config/messages.json",
      "common": "config/common.json"
    },
    "topics": {
      "pubToServer": "CS-pub",
      "subFromServer": "CS-sub"
    }
  },
}
```

In general, the following options are necessary for users to modify according to actual situations,

- database.mysql.username: the username of MySQL
- database.mysql.password: the user's password of MySQL
- database.mysql.database: the database used for X-LoRa in MySQL
- udp.port: the port for receiving UDP packets from LoRa Gateways(default value is 1700)
- http.port: the port of HTTP interfaces(default value is 3000)

Other configurations are free to change to fit the environments.

通常，以下选项对于用户根据实际情况进行修改是必需的，

-database.mysql.username：MySQL的用户名
-database.mysql.password：MySQL的用户密码
-database.mysql.database：MySQL中用于X-LoRa的数据库
-udp.port：用于从LoRa网关接收UDP数据包的端口（默认值为1700）
-http.port：HTTP接口的端口（默认值为3000）

其他配置可以自由更改以适应环境。

---
