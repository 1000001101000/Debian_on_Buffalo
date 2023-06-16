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

echo "CREATE metadata=1.0" >> /etc/mdadm.conf
echo "CREATE metadata=1.0" >> /tmp/mdadm.conf

mkdir -p /etc/mdadm/
mkdir -p /etc/mdadm.conf.d/
mkdir -p /tmp/mdadm.conf.d/

echo "CREATE metadata=1.0" >> /etc/mdadm/mdadm.conf
echo "CREATE metadata=1.0" >> /etc/mdadm.conf.d/mdadm.conf
echo "CREATE metadata=1.0" >> /tmp/mdadm.conf.d/mdadm.conf

##default rootfs to "nodiscard" so that devices with sata expanders (TS-XEL/LS-QVL/etc) don't crash if someone uses an SSD
sed -i 's/errors=remount-ro/errors=remount-ro,nodiscard/g' /lib/partman/fstab.d/ext3

##activate a check originally included for the early linkstation which still applies
sed -i 's/\"GLAN Tank\"/\*/g' /lib/partman/check.d/10ext2_or_ext3_boot
##deactivate bootable flag check which doesn't apply to buffalo devices (I think)
sed -i 's/\$boot_bootable/yes/g' lib/partman/check.d/10ext2_or_ext3_boot
exit 0
