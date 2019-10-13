##requires uboot-tools, gzip, faketime, rsync, wget, cpio, libarchive-cpio-perl
## making this smaller via a PPA sounds like fun.

dtb_dir="../../device_trees"
tools_dir="../../../Tools"
distro="stretch"

mkdir output 2>/dev/null
mkdir armel-files 2>/dev/null
cd armel-files
if [ -d "tmp" ]; then
   rm -r "tmp/"
fi

wget -N "http://ftp.nl.debian.org/debian/dists/$distro/main/installer-armel/current/images/kirkwood/netboot/initrd.gz"

#wget -N "https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/dists/$distro/main/binary-armel/Packages"
#kernel_deb_url="$(cat Packages | grep linux-image-4 | grep Filename | gawk '{print $2}' | tail -n 1)"
#echo $kernel_deb_url
#wget -nc "https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/$kernel_deb_url"
#kernel_deb="$(basename $kernel_deb_url)"
#kernel_ver="$(echo $kernel_deb | gawk -F[-_] '{print $3}')"

mkdir tmp

dpkg --extract linux-image-tsxl.deb tmp/
if [ $? -ne 0 ]; then
        echo "failed to unpack kernel, quitting"
        exit
fi
cd ..
rm -r payload/lib/modules/*
rsync -rtWhmv --include "*/" \
--include="*/drivers/md/*" \
--include="m25p80.ko" \
--include="spi_nor.ko" \
--include="ehci_orion.ko" \
--include="ehci_hcd.ko" \
--include="sg.ko" \
--include="marvell.ko" \
--include="usbcore.ko" \
--include="usb_common.ko" \
--include="mvmdio.ko" \
--include="mv643xx_eth.ko" \
--include="of_mdio.ko" \
--include="fixed_phy.ko" \
--include="libphy.ko" \
--include="ip_tables.ko" \
--include="x_tables.ko" \
--include="ipv6.ko" \
--include="autofs4.ko" \
--include="ext4.ko" \
--include="msdos.ko" \
--include="fat.ko" \
--include="vfat.ko" \
--include="xfs.ko" \
--include="crc16.ko" \
--include="jbd2.ko" \
--include="fscrypto.ko" \
--include="ecb.ko" \
--include="mbcache.ko" \
--include="raid10.ko" \
--include="raid456.ko" \
--include="libcrc32c.ko" \
--include="crc32c_generic.ko" \
--include="async_raid6_recov.ko" \
--include="async_memcpy.ko" \
--include="async_pq.ko" \
--include="async_xor.ko" \
--include="xor.ko" \
--include="async_tx.ko" \
--include="raid6_pq.ko" \
--include="raid0.ko" \
--include="multipath.ko" \
--include="linear.ko" \
--include="raid1.ko" \
--include="md_mod.ko" \
--include="sd_mod.ko" \
--include="sata_mv.ko" \
--include="libata.ko" \
--include="scsi_mod.ko" \
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

rm -r armel-payload/source/micon_scripts/
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
cp -v $tools_dir/micro-evtd-armel armel-payload/source/micro-evtd
if [ $? -ne 0 ]; then
        echo "failed to copy micro-evtd , quitting"
        exit
fi


zcat armel-files/initrd.gz | cpio-filter --exclude "lib/modules/*" > initrd
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

cat initrd | xz --check=crc32 -9 > initrd.xz
if [ $? -ne 0 ]; then
        echo "failed to pack initrd, quitting"
        exit
fi
mkimage -A arm -O linux -T ramdisk -C gzip -a 0x0 -e 0x0 -n installer-initrd -d initrd.xz output/initrd.buffalo.armel
if [ $? -ne 0 ]; then
        echo "failed to create initrd.buffalo, quitting"
        exit
fi

cp "$(ls armel-files/tmp/boot/vmlinuz*)" vmlinuz

devio 'wl 0xe3a01c0a,4' 'wl 0xe3811089,4' > machtype
cat machtype vmlinuz > katkern
mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n installer-kernel -d  katkern output/uImage.buffalo.tsxl

devio 'wl 0xe3a01c06,4' 'wl 0xe3811030,4' > machtype
cat machtype vmlinuz > katkern
mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n debian_installer -d  katkern output/uImage.buffalo.ts2pro

dtb_list="$(ls $dtb_dir/*{orion,kirkwood}*dtb)"

for dtb in $dtb_list
do
model="$(echo $dtb | gawk -F- '{print $NF}' | gawk -F. '{print $1}')"
cat vmlinuz $dtb > tmpkern
mkimage -A arm -O linux -T Kernel -C none -a 0x00008000 -e 0x00008000 -n debian_installer -d tmpkern output/uImage.buffalo.$model
done

rm machtype
rm katkern
rm tmpkern
rm initrd
rm vmlinuz
rm initrd.xz
rm -r armel-payload/lib/modules/*
mv output/uImage.buffalo.tsxel output/uImage-88f6281.buffalo.tsxel
