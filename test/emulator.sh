#!/bin/bash

# 仿真节点设备数据

# lora node -> gateway -> lorawan-server
if [ $# -eq 0 ] || [ "$@" == "" ]; then
    echo usage:./emulator.sh join or ./emulator.sh app  
    exit -1
fi
cd ./lora-motes-emulator/
configEmulatorInfo=`cat config.yml`
configDevice=`cat device.json`
echo "Emulator config info:\r\n$configEmulatorInfo"
echo "End device config info:\r\n$configDevice"
# pipenv shell
pipenv run python main.py -h
if [ "$1" == "join" ]; then
    # python main.py join
    pipenv run python main.py join
elif [ "$1" == "app" ]; then
    # python main.py app
    pipenv run python main.py app
else
    echo please,usage:./emulator.sh join or ./emulator.sh app
fi
cd --