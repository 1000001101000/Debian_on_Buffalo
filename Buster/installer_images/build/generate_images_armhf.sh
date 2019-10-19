##requires uboot-tools, gzip, faketime, rsync, wget, cpio?
dtb_dir="../../device_trees"
tools_dir="../../../Tools"
distro="buster"

mkdir output 2>/dev/null
mkdir armhf-files 2>/dev/null
cd armhf-files
if [ -d "tmp" ]; then
   rm -r "tmp/"
fi

wget -N "http://ftp.debian.org/debian/dists/$distro/main/installer-armhf/current/images/network-console/initrd.gz"
kernel_ver="$(zcat initrd.gz | cpio -t | grep lib/modules/ | head -n 1 | gawk -F/ '{print $3}')"
wget -N "http://ftp.debian.org/debian/dists/$distro/main/binary-armhf/Packages.gz"
kernel_deb_url="$(zcat Packages.gz | grep linux-image-$kernel_ver\_ | grep Filename | gawk '{print $2}')"
wget -N "http://ftp.debian.org/debian/$kernel_deb_url"
kernel_deb="$(basename $kernel_deb_url)"

eth_deb_url="$(zcat Packages.gz | grep ethtool | grep Filename | head -n 1 | gawk '{print $2}')"
wget -N "http://ftp.debian.org/debian/$eth_deb_url"
eth_deb="$(basename "$eth_deb_url")"
dpkg --extract $eth_deb ../armhf-payload/

mkdir tmp
dpkg --extract $kernel_deb tmp/
if [ $? -ne 0 ]; then
	echo "failed to unpack kernel, quitting"
	exit
fi
cd ..
mkdir armhf-payload/lib/ 2>/dev/null
rm -r armhf-payload/lib/modules/*
rsync -rtWhmv --include "*/" \
--include="mtdblock.ko" --include="mtd_blkdevs.ko" --include="spi-nor.ko" --include="m25p80.ko" --include="spi-orion.ko" \
--exclude="*" armhf-files/tmp/lib/ armhf-payload/lib/
if [ $? -ne 0 ]; then
        echo "failed to copy module files, quitting"
        exit
fi
cp -v $dtb_dir/*.dtb armhf-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy dtb files, quitting"
        exit
fi
cp -v $tools_dir/*.sh armhf-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy tools, quitting"
        exit
fi

rm -r armhf-payload/source/micon_scripts/
cp -vrp $tools_dir/micon_scripts/ armhf-payload/source/micon_scripts/
if [ $? -ne 0 ]; then
        echo "failed to copy tools, quitting"
        exit
fi
cp -v $tools_dir/micro-evtd-armhf armhf-payload/source/micro-evtd
if [ $? -ne 0 ]; then
        echo "failed to copy micro-evtd , quitting"
        exit
fi
cp -v $tools_dir/buffalo_devices.db armhf-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy device db, quitting"
        exit
fi
cp -v "armhf-files/tmp/boot/vmlinuz-$kernel_ver" .
if [ $? -ne 0 ]; then
        echo "failed to copy kernel, quitting"
        exit
fi
rm -r "armhf-files/tmp/"

cp armhf-files/initrd.gz .
if [ $? -ne 0 ]; then
        echo "failed to retrieve initrd.gz, quitting"
        exit
fi
gunzip initrd.gz
if [ $? -ne 0 ]; then
        echo "failed to unpack initrd.gz, quitting"
        exit
fi
cd armhf-payload
find . | cpio -v -H newc -o -A -F ../initrd
if [ $? -ne 0 ]; then
        echo "failed to patch initrd.gz, quitting"
        exit
fi
cd ..
cat initrd | xz --check=crc32 -9 > initrd.xz
if [ $? -ne 0 ]; then
        echo "failed to pack initrd, quitting"
        exit
fi
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T ramdisk -C gzip -a 0x0 -e 0x0 -n initrd -d initrd.xz output/initrd.buffalo.armhf"
if [ $? -ne 0 ]; then
        echo "failed to create initrd.buffalo, quitting"
        exit
fi
rm initrd.xz
rm initrd.gz
rm initrd
rm armhf-payload/source/*.dtb
rm armhf-payload/source/buffalo_devices.db
rm armhf-payload/source/*.deb

dtb_list="$(ls $dtb_dir/armada*.dtb)"

for dtb in $dtb_list
do
model="$(echo $dtb | gawk -F- '{print $4}' | gawk -F. '{print $1}')"
cat vmlinuz-$kernel_ver $dtb > tmpkern
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T Kernel -C none -a 0x00008000 -e 0x00008000 -n debian_installer -d tmpkern output/uImage.buffalo.$model"
done
rm tmpkern
rm vmlinuz*

