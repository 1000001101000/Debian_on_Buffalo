#!/bin/bash

if [ "$1" == "halt" ] || [ "$1" == "poweroff" ]; then
    i2cset -y -f 0 0x32 0xB0 0x43
else
    i2cset -y -f 0 0x32 0xB0 0x18
fi

exit 0
