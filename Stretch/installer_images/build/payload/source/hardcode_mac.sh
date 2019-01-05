sed -i "s/iface eth0 inet dhcp/iface eth0 inet dhcp\nhwaddress ether $(cat /source/eth0-mac.txt)/g" /target/etc/network/interfaces
sed -i "s/iface eth1 inet dhcp/iface eth1 inet dhcp\nhwaddress ether $(cat /source/eth1-mac.txt)/g" /target/etc/network/interfaces
