#!/bin/bash

##script to set mac addresses pre-ifup

ip link list | grep eth1
if [ $? -eq 0 ]; then
   eth0mac="$(fw_printenv -n ethaddr)"
   eth1mac="$(fw_printenv -n eth1addr)"
   ip link set dev eth1 address "$eth1mac"
else
   eth0mac="$(fw_printenv -n eth1addr)"
fi

ip link set dev eth0 address "$eth0mac"

exit 0
