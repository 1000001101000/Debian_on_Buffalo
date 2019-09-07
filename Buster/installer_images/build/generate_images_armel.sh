##requires uboot-tools, gzip, faketime, rsync, wget, cpio, libarchive-cpio-perl
## making this smaller via a PPA sounds like fun.
dtb_dir="../../device_trees"
tools_dir="../../../Tools"
distro="buster"

mkdir output 2>/dev/null
mkdir armel-files 2>/dev/null
cd armel-files
if [ -d "tmp" ]; then
   rm -r "tmp/"
fi

wget -N "http://ftp.nl.debian.org/debian/dists/$distro/main/installer-armel/current/images/kirkwood/netboot/initrd.gz"
wget -N "http://ftp.debian.org/debian/dists/$distro/main/binary-armel/Packages.gz"
rngd_deb_url="$(zcat Packages.gz | grep rng-tools | grep Filename | head -n 1 | gawk '{print $2}')"
wget -N "http://ftp.debian.org/debian/$rngd_deb_url"
rndg_deb="$(basename "$rngd_deb_url")"

dpkg --extract $rndg_deb ../armel-payload/


mkdir tmp

dpkg --extract linux-image.deb tmp/
if [ $? -ne 0 ]; then
        echo "failed to unpack kernel, quitting"
        exit
fi
cd ..

rm -r payload-armel/lib/modules/*
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
--include="des_generic" \
--include="evdev" \
--include="gpio_keys" \
--include="marvell_cesa" \
--include="orion_wdt" \
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
cp -vrp $tools_dir/micon_scripts_armel/ armel-payload/source/micon_scripts/
if [ $? -ne 0 ]; then
        echo "failed to copy tools, quitting"
        exit
fi
cp -v $dtb_dir/*.dtb armel-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy dtb files, quitting"
        exit
fi
cp -v $tools_dir/*.db armel-payload/source/
if [ $? -ne 0 ]; then
        echo "failed to copy device db, quitting"
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
gzip initrd
if [ $? -ne 0 ]; then
        echo "failed to pack initrd, quitting"
        exit
fi

faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T ramdisk -C gzip -a 0x0 -e 0x0 -n installer-initrd -d initrd.gz output/initrd_armel.buffalo"
if [ $? -ne 0 ]; then
        echo "failed to create initrd.buffalo, quitting"
        exit
fi

dtb_list="$(ls $dtb_dir/kirkwood*.dtb)"
cp "$(ls armel-files/tmp/boot/vmlinu*)" vmlinuz


for dtb in $dtb_list
do
model="$(echo $dtb | gawk -F- '{print $3}' | gawk -F. '{print $1}')"
cat vmlinuz $dtb > tmpkern
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T Kernel -C none -a 0x00008000 -e 0x00008000 -n debian_installer -d tmpkern output/uImage.buffalo.$model"
done

rm tmpkern
rm vmlinuz
rm initrd.gz
mv output/uImage.buffalo.tsxel output/uImage-88f6281.buffalo.tsxel
