
by https://github.com/houluy/lora-motes-emulator.git

## lora-motes-emulator 测试命令

```
usage: main.py [-h] [-v version] [-m MSG] [-f FOPTS] [-c CMD] [-u] [-n]
                           [-r {0,1,2}]
                           type

Tool for test on LoRaWAN server

positional arguments:
  type                  Data type of uplink, supported type list: ['join',
                                                'app', 'pull', 'cmd', 'rejoin', 'info', 'abp']

optional arguments:
  -h, --help            show this help message and exit
  -v version, --version version
                                                Choose LoRaWAN version, 1.0.2 or 1.1(default)
  -m MSG                FRMPayload in string
  -f FOPTS              MAC Command in FOpts field
  -c CMD                MAC Command in FRMPayload field
  -u, --unconfirmed     Enable unconfirmed data up
  -n, --new             Flag for brand new device, using device info in
                                                device.yml config file. Be careful this flag can
                                                override current device, information may be lost.
  -r {0,1,2}, --rejoin {0,1,2}
                                                Specify rejoin type, default is 0
```

## lorawan server 测试方法

1、入网请求测试

  pipenv run python main.py -n join

2、app数据测试

  pipenv run python main.py -m "testData" -u app

3、mac命令测试

  pipenv run python main.py -c 02 cmd

