#!/bin/bash

which phytool > /dev/null
if [ $? -ne 0 ]; then
   exit
fi

if [ "$1" == "halt" ] || [ "$1" == "poweroff" ]; then
    led2=8
else
    led2=9
fi

current_reg="$(phytool write eth0/0/22 3 && phytool read eth0/0/16)"
phytool write eth0/0/22 0

if [ ${#current_reg} -ne 6 ]; then
   exit
fi

new_reg=${current_reg:0:3}$led2${current_reg:4:2}

phytool write eth0/0/22 3 && phytool write eth0/0/16 $new_reg
phytool write eth0/0/22 0


