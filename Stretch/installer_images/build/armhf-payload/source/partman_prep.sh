echo "CREATE metadata=0.90" >> /etc/mdadm.conf
echo "CREATE metadata=0.90" >> /tmp/mdadm.conf

mkdir -p /etc/mdadm/
mkdir -p /etc/mdadm.conf.d/
mkdir -p /tmp/mdadm.conf.d/

echo "CREATE metadata=0.90" >> /etc/mdadm/mdadm.conf
echo "CREATE metadata=0.90" >> /etc/mdadm.conf.d/mdadm.conf
echo "CREATE metadata=0.90" >> /tmp/mdadm.conf.d/mdadm.conf
exit 0
