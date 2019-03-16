conf_file="/target/etc/network/interfaces"
mac0="$(cat /source/eth0-mac.txt)"
mac1="$(cat /source/eth1-mac.txt)"

grep $mac0 $conf_file > /dev/null
if [ $? -ne 0 ]; then
        sed -i "s/iface eth0 inet dhcp/iface eth0 inet dhcp\nhwaddress ether $mac0/g" "$conf_file"
fi

grep $mac1 $conf_file > /dev/null
if [ $? -ne 0 ]; then
        sed -i "s/iface eth1 inet dhcp/iface eth1 inet dhcp\nhwaddress ether $mac1/g" "$conf_file"
fi
