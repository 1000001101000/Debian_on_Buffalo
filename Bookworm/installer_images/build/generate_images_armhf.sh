##requires uboot-tools, gzip, faketime, rsync, wget, cpio?
dtb_dir="../../device_trees"
tools_dir="../../../Tools"
distro="bookworm"

mkdir output 2>/dev/null
rm output/*
rm -r armhf-payload/* 2>/dev/null
mkdir -p armhf-payload/source/ 2>/dev/null
mkdir armhf-files 2>/dev/null
cd armhf-files
if [ -d "tmp" ]; then
   rm -r "tmp/"
fi

wget -N "http://ftp.debian.org/debian/dists/$distro/main/installer-armhf/current/images/network-console/initrd.gz" 2>/dev/null
kernel_ver="$(zcat initrd.gz | cpio -t | grep -m 1 lib/modules/ | gawk -F/ '{print $3}')"
wget -N "http://ftp.debian.org/debian/dists/$distro/main/binary-armhf/Packages.gz" 2>/dev/null
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
mkdir armhf-payload/lib/ 2>/dev/null
rm -r armhf-payload/lib/modules/* 2>/dev/null

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
cp -v $tools_dir/0-install_shim armhf-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy shim tools, quitting"
        exit
fi
cp -v $tools_dir/bootshim/armhf_shim armhf-payload/source/bootshim
if [ $? -ne 0 ]; then
        echo "failed to copy boot shim, quitting"
        exit
fi
rm -r armhf-payload/source/micon_scripts/ 2>/dev/null
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
cp -v $tools_dir/*.db armhf-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy device db, quitting"
        exit
fi
cp -v preseed-armhf.cfg armhf-payload/preseed.cfg
if [ $? -ne 0 ]; then
        echo "failed to copy preseed, quitting"
        exit
fi
cp -v "armhf-files/tmp/boot/vmlinuz-$kernel_ver" .
if [ $? -ne 0 ]; then
        echo "failed to copy kernel, quitting"
        exit
fi
rm -r "armhf-files/tmp/" 2>/dev/null

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
rm initrd
rm armhf-payload/source/*.dtb
rm armhf-payload/source/*.db
rm armhf-payload/source/*.deb

dtb_list="$(ls $dtb_dir/armada*.dtb)"

for dtb in $dtb_list
do
model="$(echo $dtb | gawk -F- '{print $4}' | gawk -F. '{print $1}')"
cat armhf-payload/source/bootshim vmlinuz-$kernel_ver $dtb > tmpkern
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T Kernel -C none -a 0x00008000 -e 0x00008000 -n debian_installer -d tmpkern output/uImage.buffalo.$model"
done

##remove TS3400 devices until we have a fix for their PCI issue
rm output/*3400*

rm tmpkern
rm vmlinuz*

