#!/bin/bash

custom_kernel()
{
  apt-get -y remove $(dpkg -l | grep linux-image | gawk '{print $2}')
  apt-get install -y apt-transport-https gnupg
  wget -qO - https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/KEY.gpg | apt-key add -
  echo "deb https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/ $version main" > /etc/apt/sources.list.d/buffalo_kernel.list
  apt-get update
  apt-get install -y linux-image-$1
}

version="$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f 2)"

echo "BOOT=local" > /usr/share/initramfs-tools/conf.d/localboot
echo "MODULES=dep" > /etc/initramfs-tools/conf.d/modules
echo mtdblock >> /etc/modules
echo m25p80 >> /etc/modules
echo spi_nor >> /etc/modules

machine=`sed -n '/Hardware/ {s/^Hardware\s*:\s//;p}' /proc/cpuinfo`
case $machine in
        *"Device Tree)")
        machine=$(cat /proc/device-tree/model)
        ;;
esac

mount -t proc none /proc
mount -t sysfs none /sys

udevadm trigger

run_size="$(busybox df -m /run | busybox tail -n 1 | busybox awk '{print $2}')"

##increase /run if default is too low
if [ $run_size -lt 20 ]; then
  mount -o remount,nosuid,noexec,size=26M,nr_inodes=4096 /run
fi

if [ "$(busybox grep -c "Marvell Armada 370/XP" /proc/cpuinfo)" == "0" ]; then
   case $machine in
        "Buffalo Nas WXL")
           custom_kernel marvell-buffalo;;
        "Buffalo Linkstation LS-QL")
           custom_kernel marvell-buffalo;;
	"Buffalo Terastation Pro II/Live")
	   custom_kernel marvell-buffalo;;
        *)
        apt-get install -y linux-image-marvell;;
   esac
else
    ln -s /usr/local/bin/ifup-mac.sh /etc/network/if-pre-up.d/ifup_mac
fi

if [ "$(/usr/local/bin/micro-evtd -s 0003 | tail -n 1)" == "0" ]; then
	ln -s /usr/local/bin/micon_scripts/micon_shutdown.py /lib/systemd/system-shutdown/micon_shutdown.py

	systemctl enable micon_boot.service
	systemctl enable micon_fan_daemon.service

	##signal restart rather than shutdown
	/usr/local/bin/micro-evtd -s 013500,0003,000c,014618
else
  if [ "$machine" == "Buffalo Linkstation LS-QL" ]; then
    ln -s /usr/local/bin/rtc_restart.sh /lib/systemd/system-shutdown/rtc_restart.sh
    i2cset -y -f 0 0x32 0xB0 0x18
  else
    ln -s /usr/local/bin/phy_restart.sh /lib/systemd/system-shutdown/phy_restart.sh
    /usr/local/bin/phytool write eth0/0/22 3 && /usr/local/bin/phytool write eth0/0/16 0x0981
    /usr/local/bin/phytool write eth0/0/22 0
  fi
fi

apt-get install -y flash-kernel
echo "" | update-initramfs -u

exit 0
