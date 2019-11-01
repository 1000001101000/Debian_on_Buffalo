#!/bin/bash

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

case $machine in
        "Buffalo Nas WXL")
	apt-get -y remove $(dpkg -l | grep linux-image | gawk '{print $2}')
	apt-get install -y apt-transport-https gnupg
        wget -qO - https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/KEY.gpg | apt-key add -
        echo "deb https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/ buster main" > /etc/apt/sources.list.d/tsxl_kernel.list
        apt-get update
	has_pci="$(lspci | wc -c)"
	if [ $has_pci -ne 0 ]; then
           apt-get install -y linux-image-tsxl
	else
	   apt-get install -y linux-image-tswxl
	fi
	;;
        *)
        apt-get install -y linux-image-marvell;;
esac

apt-get install -y flash-kernel
echo "" | update-initramfs -u

if [ "$(/usr/local/bin/micro-evtd -s 0003 | tail -n 1)" == "0" ]; then
	ln -s /usr/local/bin/micon_scripts/micon_shutdown.py /lib/systemd/system-shutdown/micon_shutdown.py

	systemctl enable micon_boot.service
	systemctl enable micon_fan_daemon.service

	##signal restart rather than shutdown
	/usr/local/bin/micro-evtd -s 013500,0003,000c,014618
fi

exit 0
