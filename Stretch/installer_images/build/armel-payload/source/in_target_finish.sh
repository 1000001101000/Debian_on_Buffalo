machine=`sed -n '/Hardware/ {s/^Hardware\s*:\s//;p}' /proc/cpuinfo`
case $machine in
        *"(Flattened Device Tree)")
        machine=$(cat /proc/device-tree/model)
        ;;
esac


mount -t proc none /proc
mount -t sysfs none /sys

run_size="$(busybox df -m /run | busybox tail -n 1 | busybox awk '{print $2}')"

##increase /run if default is too low
if [ $run_size -lt 20 ]; then
  echo "tmpfs /run tmpfs nosuid,noexec,size=26M,nr_inodes=4096 0  0" >> /etc/fstab
  mount -o remount tmpfs
fi

##not bothering to skip if not needed, presumably the files wouldn't have copied
systemctl enable micon_boot.service
systemctl enable micon_fan_daemon.service

if [ "$machine" != "Buffalo Nas WXL" ]; then
   apt-get install -y linux-image-marvell
else
   apt-get install -y apt-transport-https
   wget -qO - https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/KEY.gpg | apt-key add -
   echo "deb https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/ stretch main" > /etc/apt/sources.list.d/tsxl_kernel.list

   apt-get update
   has_pci="$(lspci | wc -c)"
   if [ $has_pci -ne 0 ]; then
      apt-get install -y linux-image-tsxl
   else
      apt-get install -y linux-image-tswxl
   fi
fi


exit 0
