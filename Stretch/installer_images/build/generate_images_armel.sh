##requires uboot-tools, gzip, faketime, rsync, wget, cpio, libarchive-cpio-perl

dtb_dir="../../device_trees"
tools_dir="../../../Tools"
distro="stretch"

mkdir output 2>/dev/null
rm -r armel-payload/*
mkdir armel-files 2>/dev/null
mkdir -p armel-payload/source/ 2>/dev/null
cd armel-files
if [ -d "tmp" ]; then
   rm -r "tmp/"
fi

wget -N "http://ftp.nl.debian.org/debian/dists/$distro/main/installer-armel/current/images/kirkwood/netboot/initrd.gz"

wget -N https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/dists/$distro/main/binary-armel/Packages
searchfrom="$(grep -n Package:\ linux-image-tsxl Packages | cut -d ':' -f 1)"
kpkg="$(tail -n +$searchfrom Packages | grep Depends: | head -n 1 | cut -d ' ' -f 2)"
kernel_deb_url="$(cat Packages | grep Filename: | grep $kpkg | gawk '{print $2}')"
wget -nc "https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/$kernel_deb_url"
kernel_deb="$(basename $kernel_deb_url)"

mkdir tmp

dpkg --extract $kernel_deb tmp/
if [ $? -ne 0 ]; then
        echo "failed to unpack kernel, quitting"
        exit
fi
cd ..
rm -r armel-payload/lib/modules/*
rsync -rtWhmv --include "*/" \
--include="*/drivers/md/*" \
--include="dm-persistent-data.ko" \
--include="af_alg.ko" \
--include="af_packet.ko" \
--include="algif_skcipher.ko" \
--include="arc4.ko" \
--include="async_memcpy.ko" \
--include="async_pq.ko" \
--include="async_raid6_recov.ko" \
--include="async_tx.ko" \
--include="async_xor.ko" \
--include="autofs4.ko" \
--include="bch.ko" \
--include="bcache.ko" \
--include="blowfish_common.ko" \
--include="blowfish_generic.ko" \
--include="cbc.ko" \
--include="ccm.ko" \
--include="cfi_probe.ko" \
--include="cfi_util.ko" \
--include="chipreg.ko" \
--include="crc16.ko" \
--include="crc32c_generic.ko" \
--include="crc64.ko" \
--include="crc7.ko" \
--include="crc-ccitt.ko" \
--include="crc-itu-t.ko" \
--include="ctr.ko" \
--include="dax.ko" \
--include="dm-bio-prison.ko" \
--include="dm-bufio.ko" \
--include="dm-cache.ko" \
--include="dm-cache-smq.ko" \
--include="dm-crypt.ko" \
--include="dm-delay.ko" \
--include="dm-era.ko" \
--include="dm-flakey.ko" \
--include="dm-log.ko" \
--include="dm-log-userspace.ko" \
--include="dm-log-writes.ko" \
--include="dm-mirror.ko" \
--include="dm-mod.ko" \
--include="dm-multipath.ko" \
--include="dm-queue-length.ko" \
--include="dm-raid.ko" \
--include="dm-region-hash.ko" \
--include="dm-round-robin.ko" \
--include="dm-service-time.ko" \
--include="dm-snapshot.ko" \
--include="dm-switch.ko" \
--include="dm-thin-pool.ko" \
--include="dm-verity.ko" \
--include="dm-zero.ko" \
--include="ecb.ko" \
--include="ext4.ko" \
--include="fat.ko" \
--include="faulty.ko" \
--include="fixed_phy.ko" \
--include="firmware_class.ko" \
--include="fscrypto.ko" \
--include="gen_probe.ko" \
--include="ip_tables.ko" \
--include="ipv6.ko" \
--include="jbd2.ko" \
--include="leds-gpio.ko" \
--include="ledtrig-gpio.ko" \
--include="libata.ko" \
--include="libcrc32c.ko" \
--include="libphy.ko" \
--include="linear.ko" \
--include="marvell.ko" \
--include="mbcache.ko" \
--include="md-mod.ko" \
--include="mii.ko" \
--include="msdos.ko" \
--include="multipath.ko" \
--include="mv643xx_eth.ko" \
--include="mvmdio.ko" \
--include="nls_base.ko" \
--include="nls_utf8.ko" \
--include="of_mdio.ko" \
--include="ofpart.ko" \
--include="omap-rng.ko" \
--include="physmap_of.ko" \
--include="pps_core.ko" \
--include="ptp.ko" \
--include="raid0.ko" \
--include="raid10.ko" \
--include="raid1.ko" \
--include="raid456.ko" \
--include="raid6_pq.ko" \
--include="rng-core.ko" \
--include="sata_mv.ko" \
--include="scsi_mod.ko" \
--include="sd_mod.ko" \
--include="serpent_generic.ko" \
--include="sg.ko" \
--include="sha256_generic.ko" \
--include="twofish_common.ko" \
--include="twofish_generic.ko" \
--include="vfat.ko" \
--include="xfs.ko" \
--include="xor.ko" \
--include="x_tables.ko" \
--include="xts.ko" \
--include="zlib_deflate.ko" \
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


zcat armel-files/initrd.gz | cpio-filter --exclude "lib/modules/*" > initrd1
cat initrd1 | cpio-filter --exclude "sbin/wpa_supplicant" > initrd
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
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T ramdisk -C gzip -a 0x0 -e 0x0 -n installer-initrd -d initrd.xz output/initrd.buffalo.armel"
if [ $? -ne 0 ]; then
        echo "failed to create initrd.buffalo, quitting"
        exit
fi

cp "$(ls armel-files/tmp/boot/vmlinuz*)" vmlinuz

devio 'wl 0xe3a01c0a,4' 'wl 0xe3811089,4' > machtype
cat machtype vmlinuz > katkern
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n installer-kernel -d  katkern output/uImage.buffalo.tsxl"

devio 'wl 0xe3a01c06,4' 'wl 0xe3811030,4' > machtype
cat machtype vmlinuz > katkern
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T kernel -C none -a 0x00008000 -e 0x00008000 -n debian_installer -d  katkern output/uImage.buffalo.ts2pro"

dtb_list="$(ls armel-files/dtb/*{orion,kirkwood}*dtb)"

for dtb in $dtb_list
do
model="$(echo $dtb | gawk -F- '{print $NF}' | gawk -F. '{print $1}')"
cat vmlinuz $dtb > tmpkern
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T Kernel -C none -a 0x00008000 -e 0x00008000 -n debian_installer -d tmpkern output/uImage.buffalo.$model"
done

dtb_list="$(ls $dtb_dir/*{orion,kirkwood}*dtb)"

for dtb in $dtb_list
do
model="$(echo $dtb | gawk -F- '{print $NF}' | gawk -F. '{print $1}')"
cat vmlinuz $dtb > tmpkern
faketime '2018-01-01 01:01:01' /bin/bash -c "mkimage -A arm -O linux -T Kernel -C none -a 0x00008000 -e 0x00008000 -n debian_installer -d tmpkern output/uImage.buffalo.$model"
done

rm machtype
rm katkern
rm tmpkern
rm vmlinuz
rm initrd
rm initrd1
rm initrd.xz
rm -r armel-payload/lib/modules/*
mv output/uImage.buffalo.tsxel output/uImage-88f6281.buffalo.tsxel
