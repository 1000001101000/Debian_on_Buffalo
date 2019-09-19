model="$(cat /proc/device-tree/model)"
if [ "$model" == "Buffalo Linkstation LS441D" ]; then
   /source/phytool write eth0/0/22 3 && /source/phytool write eth0/0/16 0x0981
   /source/phytool write eth0/0/22 0
fi

exit 0
