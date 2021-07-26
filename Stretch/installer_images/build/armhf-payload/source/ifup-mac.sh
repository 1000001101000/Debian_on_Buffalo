#!/bin/sh

##script to set mac addresses pre-ifup

modprobe spi_nor
modprobe m25p80
sleep 2

mtd_devs="$(ls /sys/block | grep mtdb)"

for dev in $mtd_devs
do

   dd if=/dev/$dev of=/tmp/ddtmp bs=1M count=2

  ethaddr="$(strings /tmp/ddtmp  | grep -e ^ethaddr=  | cut -d= -f 2)"
  eth1addr="$(strings /tmp/ddtmp | grep -e ^eth1addr= | cut -d= -f 2)"

  > /tmp/ddtmp
  if [ -z "${eth1addr}" ]; then
    continue
  fi

  break

done

ip link list | grep eth1
if [ $? -eq 0 ]; then
   eth0mac="$ethaddr"
   eth1mac="$eth1addr"
   ip link set dev eth1 address "$eth1mac"
else
   eth0mac="$eth1addr"
fi

ip link set dev eth0 address "$eth0mac"

exit 0
