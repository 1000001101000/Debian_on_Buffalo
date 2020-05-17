#!/bin/bash
##requires uboot-tools, gzip, faketime, rsync, wget, cpio, libarchive-cpio-perl

dtb_dir="../../device_trees"
tools_dir="../../../Tools"
distro="buster"

mkdir output 2>/dev/null
rm output/*
rm -r armel-payload/* 2>/dev/null
mkdir armel-files 2>/dev/null
mkdir -p armel-payload/source/ 2>/dev/null
cd armel-files
if [ -d "tmp" ]; then
   rm -r "tmp/"
fi

wget -N "http://ftp.nl.debian.org/debian/dists/$distro/main/installer-armel/current/images/kirkwood/netboot/initrd.gz" 2>/dev/null

kernel_ver="$(zcat initrd.gz | cpio -t | grep -m 1 lib/modules/ | gawk -F/ '{print $3}')"
wget -N "http://ftp.debian.org/debian/dists/$distro/main/binary-armel/Packages.gz" 2>/dev/null
kernel_deb_url="$(zcat Packages.gz | grep linux-image-$kernel_ver\_ | grep Filename | gawk '{print $2}')"
wget -N "http://ftp.debian.org/debian/$kernel_deb_url" 2>/dev/null
kernel_deb="$(basename $kernel_deb_url)"

mkdir tmp

dpkg --extract $kernel_deb tmp/
if [ $? -ne 0 ]; then
        echo "failed to unpack kernel, quitting"
        exit
fi
cd ..

rm -r armel-payload/lib/modules/* 2>/dev/null
rsync -rtWhmv --include "*/" \
--include="sd_mod.ko" \
--include="sata_mv.ko" \
--include="libata.ko" \
--include="scsi_mod.ko" \
--include="leds-gpio.ko" \
--exclude="*" armel-files/tmp/lib/ armel-payload/lib/
if [ $? -ne 0 ]; then
        echo "failed to copy module files, quitting"
        exit
fi

cp -v $tools_dir/*.sh armel-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy tools, quitting"
        exit
fi

rm -r armel-payload/source/micon_scripts/ 2>/dev/null
cp -vrp $tools_dir/micon_scripts armel-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy micon tools, quitting"
        exit
fi
cp -v $dtb_dir/{orion,kirkwood}*.dtb armel-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy dtb files, quitting"
        #exit
fi
cp -v $tools_dir/*.db armel-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy device db, quitting"
        exit
fi
cp -v preseed-armel.cfg armel-payload/preseed.cfg
if [ $? -ne 0 ]; then
        echo "failed to copy preseed, quitting"
        exit
fi
cp -v $tools_dir/micro-evtd-armel armel-payload/source/micro-evtd
if [ $? -ne 0 ]; then
        echo "failed to copy micro-evtd , quitting"
        exit
fi
cp -v $tools_dir/phytool-armel armel-payload/source/phytool
if [ $? -ne 0 ]; then
        echo "failed to copy phytool , quitting"
        exit
fi

#zcat armel-files/initrd.gz | cpio-filter --exclude "lib/modules/*" > initrd1
zcat armel-files/initrd.gz | \
cpio-filter --exclude "sbin/wpa_supplicant" | \
cpio-filter --exclude "*/kernel/drivers/video" | \
cpio-filter --exclude "*/kernel/drivers/mmc" | \
cpio-filter --exclude "*/kernel/drivers/staging" | \
cpio-filter --exclude "*/kernel/drivers/usb" | \
cpio-filter --exclude "*/kernel/drivers/hid" > initrd
if [ $? -ne 0 ]; then
        echo "failed to unpack initrd, quitting"
        exit
fi

cd armel-payload

find . | cpio -v -H newc -o -A -F ../initrd
if [ $? -ne 0 ]; then
        echo "failed to patch initrd.gz, quitting"
        exit
fi
cd ..

gzip initrd
if [ $? -ne 0 ]; then
        echo "failed to pack gz initrd, quitting"
        exit 99
fi

faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T ramdisk -C gzip -a 0x0 -e 0x0 -n installer-initrd -d initrd.gz output/initrd.buffalo.armel-lowmem"
if [ $? -ne 0 ]; then
        echo "failed to create initrd.buffalo.armel-lowmem, quitting"
        exit
fi

cp "$(ls armel-files/tmp/boot/vmlinuz*)" vmlinuz

dtb_list="$(ls armel-files/dtb/*{orion,kirkwood}*dtb)"
dtb_list="$dtb_dir/kirkwood-linkstation-lsxl.dtb $dtb_dir/orion5x-linkstation-lswtgl.dtb $dtb_dir/kirkwood-lschlv2.dtb"

for dtb in $dtb_list
do
model="$(echo $dtb | gawk -F- '{print $NF}' | gawk -F. '{print $1}')"
cat vmlinuz $dtb > tmpkern
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T Kernel -C none -a 0x01a00000 -e 0x01a00000 -n debian_installer -d tmpkern output/uImage.buffalo.$model"
done

cp vmlinuz output/vmlinuz-armel

rm tmpkern
rm vmlinuz
rm initrd*
rm -r armel-payload/*

