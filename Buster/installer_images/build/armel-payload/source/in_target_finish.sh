machine=`sed -n '/Hardware/ {s/^Hardware\s*:\s//;p}' /proc/cpuinfo`
case $machine in
        *"(Flattened Device Tree)")
        machine=$(cat /proc/device-tree/model)
        ;;
esac

micon_version="$(/source/micro-evtd -s 8083)"

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

case $machine in
        "Buffalo Terastation Pro II/Live" | "Buffalo Nas WXL")
	apt-get install -y apt-transport-https gnupg
        wget -qO - https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/KEY.gpg | apt-key add -
        echo "deb https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/ buster main" > /etc/apt/sources.list.d/tsxl_kernel.list
        apt-get update
        apt-get install -y linux-image-tsxl;;
        *)
        apt-get install -y linux-image-marvell;;
esac

exit 0
