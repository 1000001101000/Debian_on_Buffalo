#!/bin/bash
# place in /lib/systemd/system-shutdown/ for debian based systems
# other systems it's /usr/lib/systemd/system-shutdown/

phytool="/usr/local/bin/phytool"

##I think only needed for dhcp leases file
mount -o remount,rw /

ifup --no-scripts --force eth0
sleep 2
mount -o remount,ro /

$phytool write eth0/0/22 3
if [ "$1" == "halt" ] || [ "$1" == "poweroff" ]; then
    $phytool write eth0/0/16 0x0881
else
    $phytool write eth0/0/16 0x0981
fi
$phytool write eth0/0/22 0

exit 0

