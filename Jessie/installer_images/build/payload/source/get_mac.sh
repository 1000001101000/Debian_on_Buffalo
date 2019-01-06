depmod
sleep 10
rmmod mtdblock
modprobe marvell
modprobe spi_orion
sleep 2
modprobe spi_nor
sleep 2
modprobe m25p80
sleep 2
modprobe mtdblock
sleep 2
ip link list | grep eth1
if [ $? -eq 0 ]; then
   /source/fw_printenv -n ethaddr > /source/eth0-mac.txt && /source/set_mac.sh "eth0" "$(cat /source/eth0-mac.txt)"
   /source/fw_printenv -n eth1addr > /source/eth1-mac.txt && /source/set_mac.sh "eth1" "$(cat /source/eth1-mac.txt)"
else
   /source/fw_printenv -n eth1addr > /source/eth0-mac.txt && /source/set_mac.sh "eth0" "$(cat /source/eth0-mac.txt)"
fi
exit 0
