file="/etc/mke2fs.conf"
old=$file.old
new=$file.new

cp $file $old

top="$(grep -n ext3\ \=\  $file | cut -d ':' -f 1)"
top="$((top-1))"
bottom="$(grep -n ext4\ \=\  $file | cut -d ':' -f 1)"

head -n $top $file > $new

echo -e "\text2 = {\n\t\tinode_size = 128\n\t}" >> $new
echo -e "\text3 = {\n\t\tfeatures = has_journal\n\t\tinode_size = 128\n\t}" >> $new

tail -n +$bottom $file >> $new

cp $new $file

echo "CREATE metadata=0.90" >> /etc/mdadm.conf
echo "CREATE metadata=0.90" >> /tmp/mdadm.conf

mkdir -p /etc/mdadm/
mkdir -p /etc/mdadm.conf.d/
mkdir -p /tmp/mdadm.conf.d/

echo "CREATE metadata=0.90" >> /etc/mdadm/mdadm.conf
echo "CREATE metadata=0.90" >> /etc/mdadm.conf.d/mdadm.conf
echo "CREATE metadata=0.90" >> /tmp/mdadm.conf.d/mdadm.conf
exit 0
