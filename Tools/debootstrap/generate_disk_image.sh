#!/bin/bash

##set some vars.
target="/mnt/target"
target_hostname="tsxel"
machine="Buffalo Terastation TS-XEL"
#machine="Buffalo Terastation TS3400D"
#machine="Buffalo Linkstation LS-QVL"
arch="armel"
#arch="armhf"
target_rootpw="changeme"
target_user="debian"
target_userpw="changeme"
#distro="bullseye"
distro="bookworm"
boot_size="512"
swap_size="1024"
root_size="2048"
use_raid="N"

has_micon="N"
if [ "$machine" == "Buffalo Terastation Pro II/Live" ] || [ "$machine" == "Buffalo Terastation TS-XEL" ] || [ "$machine" == "Buffalo Nas WXL" ] || [ "$machine" == "Buffalo Terastation III" ] || [ "$machine" == "Buffalo Linkstation Pro/Live" ] || [ "$machine" == "Buffalo/Revogear Kurobox Pro" ]; then
  has_micon="Y"
fi

chroot_only="N"

if [ "$machine" == "Buffalo Terastation TS1400D" ] || [ "$machine" == "Buffalo Terastation TS1400R" ] || [ "$machine" == "Buffalo Terastation TS3200D" ]  || [ "$machine" == "Buffalo Terastation TS3400D" ] || [ "$machine" == "Buffalo Terastation TS3400R" ]; then
  has_micon="Y"
fi

if [ "$machine" == "Buffalo Linkstation LS510D" ] || [ "$machine" == "Buffalo Linkstation LS520D" ]; then
  chroot_only="Y"
fi

umount_stop_temp_devs()
{
  for x in "$target/boot" "$target/dev" "$target/proc" "$target/sys" "$target/" /dev/md90 /dev/md91 /dev/md92
  do
    umount "$x" 2>/dev/null
  done

  for x in /dev/md90 /dev/md91 /dev/md92
  do
    mdadm --stop "$x" 2>/dev/null
  done

  losetup -D
}

umount_stop_temp_devs

if [ $chroot_only == "Y" ]; then
  total_size=$((root_size+2))
  root_size="+""$root_size""M"
else
  total_size=$((boot_size+swap_size+root_size+2))
  boot_size="+""$boot_size""M"
  swap_size="+""$swap_size""M"
fi

##create potential disk
image_name="debian_""$distro""_""$arch"".img"
dd if=/dev/zero of="$image_name" bs=1M count=$total_size 2>/dev/null
if [ $? -ne 0 ]; then
  echo "create image failed, drive could be full or insufficient permissions."
  exit 99
fi

echo "image file created"

if [ $chroot_only != "Y" ]; then
##partition the disk image
fdisk "$image_name" <<EOF >/dev/null

n
p
1

$boot_size
n
p
2

$swap_size
n
p
3


p
w
EOF
else
fdisk "$image_name" <<EOF >/dev/null

n
p
1

$root_size

p
w
EOF
fi
if [ $? -ne 0 ]; then
  echo "paritioning failed"
  exit 99
fi

echo "partitioning done"

##create loop devs out of partitions
losetup -f -P "$image_name"

echo "block devs created"

base_dev="$(losetup | grep $image_name | awk '{print $1}')"
boot_dev="$base_dev""p1"
swap_dev="$base_dev""p2"
root_dev="$base_dev""p3"

if [ "$use_raid" == "Y" ]; then
  mdadm -C /dev/md90 --metadata=0.90 -l 1 -n 1 "$boot_dev" --force
  if [ $? -ne 0 ]; then
    echo "failed to create raid for /boot/"
    exit 99
  fi
  boot_dev="/dev/md90"
  mdadm -C /dev/md91 --metadata=0.90 -l 1 -n 1 "$swap_dev" --force
  if [ $? -ne 0 ]; then
    echo "failed to create raid for swap"
    exit 99
  fi
  swap_dev="/dev/md91"
  mdadm -C /dev/md92 --metadata=0.90 -l 1 -n 1 "$root_dev" --force
  if [ $? -ne 0 ]; then
    echo "failed to create raid for rootfs"
    exit 99
  fi
  root_dev="/dev/md92"
  echo "raid devices created"
fi

if [ $chroot_only == "Y" ]; then
  root_dev="$base_dev""p1"
  mkfs.ext3 "$root_dev" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "failed to format rootfs"
    exit 99
  fi
  echo "rootfs formatted"
else
  mkfs.ext3 -I 128 "$boot_dev" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "failed to format /boot/"
    exit 99
  fi
  echo "/boot/ formatted"
  mkswap "$swap_dev" > /dev/null
  if [ $? -ne 0 ]; then
    echo "failed to create swap"
    exit 99
  fi
  echo "swap created"
  mkfs.ext4 "$root_dev" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "failed to format rootfs"
    exit 99
  fi
  echo "rootfs formatted"
fi

echo "format done"

boot_id="$(blkid -o export $boot_dev | grep -e ^UUID= | awk -F= '{print $2}')"
swap_id="$(blkid -o export $swap_dev | grep -e ^UUID= | awk -F= '{print $2}')"
root_id="$(blkid -o export $root_dev | grep -e ^UUID= | awk -F= '{print $2}')"

##mount them as neeeded
mkdir "$target" 2>/dev/null
mount "$root_dev" "$target"
if [ $? -ne 0 ]; then
  echo "failed to mount rootfs"
  exit 99
fi

if [ $chroot_only != "Y" ]; then
  mkdir "$target/boot"
  mount "$boot_dev" "$target/boot"
  if [ $? -ne 0 ]; then
    echo "failed to mount /boot/"
    exit 99
  fi
fi

qemu-debootstrap --arch "$arch" --include=flash-kernel,haveged,openssh-server,busybox,libpam-systemd,dbus,u-boot-tools,mdadm,gdisk,apt-transport-https,gnupg,wget,ca-certificates,python3,python3-serial,i2c-tools,xz-utils,bsdextrautils,binutils,debconf,locales "$distro" "$target" http://deb.debian.org/debian/
if [ $? -ne 0 ]; then
  echo "debootstrap reported failure"
  exit 99
fi
echo "debootstrap finished"

echo "$machine" > "$target/etc/flash-kernel/machine"

mount -t proc none "$target/proc/"
mount -t sysfs none "$target/sys/"
mount -o bind /dev "$target/dev/"

#add prereq for qemu
cp /usr/bin/qemu-arm-static "$target/usr/bin/"
if [ $? -ne 0 ]; then
  echo "failed to setup qemu chroot"
  exit 99
fi

if [ $chroot_only == "Y" ]; then
  umount_stop_temp_devs
  exit 0
fi

##generate fstab
echo -e "UUID=$root_id\t/\text4\terrors=remount-ro,nodiscard\t0\t1" >> "$target/etc/fstab"
echo -e "UUID=$boot_id\t/boot\text3\tdefaults\t0\t2" >> "$target/etc/fstab"
echo -e "UUID=$swap_id\tnone\tswap\tsw\t0\t0" >> "$target/etc/fstab"

echo "fstab built"

echo "auto lo" >> "$target/etc/network/interfaces"
echo "iface lo inet loopback" >> "$target/etc/network/interfaces"
echo "" >> "$target/etc/network/interfaces"
echo "allow-hotplug eth0" >> "$target/etc/network/interfaces"
echo "iface eth0 inet dhcp" >> "$target/etc/network/interfaces"

echo "network configuration created"

echo "$target_hostname" > "$target/etc/hostname"

echo "hostname set"

##my customizations micon/etc
cp "../micro-evtd-$arch" "$target/usr/local/bin/micro-evtd"
cp -r "../micon_scripts" "$target/usr/local/bin/"
cp ../micon_scripts/*.service "$target/etc/systemd/system/"
chmod 755 $target/usr/local/bin/micon_scripts/*.py
cp "../phytool-$arch" "$target/usr/local/bin/phytool"
cp "../phy_restart.sh" "$target/usr/local/bin/"
cp "../rtc_restart.sh" "$target/usr/local/bin/"
#cp "../ifup-mac.sh" "$target/usr/local/bin/"

cp "../0-install_shim" "$target/etc/initramfs/post-update.d/"

cp ../../${distro^}/device_trees/*.dtb "$target/etc/flash-kernel/dtbs/"
if [ $? -ne 0 ]; then
  echo "device-tree install failed"
  exit 99
fi

echo "device-trees installed"

cp ../*.db "$target/usr/share/flash-kernel/db/"

##initrd hooks/config for sure.
echo "COMPRESS=xz"    > "$target/usr/share/initramfs-tools/conf.d/compress"
echo "XZ_OPT=-2e"    >> "$target/usr/share/initramfs-tools/conf.d/compress"
echo "export XZ_OPT" >> "$target/usr/share/initramfs-tools/conf.d/compress"
echo "BOOT=local" > "$target/usr/share/initramfs-tools/conf.d/localboot"
echo "MODULES=dep" > "$target/etc/initramfs-tools/conf.d/modules"

cp ../runsize.sh "$target/etc/initramfs-tools/scripts/init-bottom/"

for module in sata_mv libata ahci libahci
do
  echo $module >> "$target/etc/initramfs-tools/modules"
done

echo "custom files/scripts copied"

##set users and passwords
echo "#!/bin/bash" >> "$target/users.sh"
echo "passwd << EOF" >>"$target/users.sh"
echo "$target_rootpw" >> "$target/users.sh"
echo "$target_rootpw" >> "$target/users.sh"
echo "EOF" >> "$target/users.sh"

echo "adduser $target_user <<EOF" >> "$target/users.sh"
echo "$target_userpw" >> "$target/users.sh"
echo "$target_userpw" >> "$target/users.sh"
echo "" >> "$target/users.sh"
echo "" >> "$target/users.sh"
echo "" >> "$target/users.sh"
echo "" >> "$target/users.sh"
echo "" >> "$target/users.sh"
echo "Y" >> "$target/users.sh"
echo "EOF" >> "$target/users.sh"

chmod +x "$target/users.sh"
chroot "$target" "/users.sh" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "user setup failed"
  exit 99
fi
rm "$target/users.sh"

echo "user setup complete"

##setup fw_printenv
if [ "$arch" == "armhf" ]; then
  echo '/dev/mtdblock1 0x00000 0x10000 0x10000' > "$target/etc/fw_env.config"
fi

##logic for ifup script, just armhf
#if [ "$arch" == "armhf" ]; then
#  chroot "$target" /bin/bash -c "ln -s /usr/local/bin/ifup-mac.sh /etc/network/if-pre-up.d/ifup_mac"
#fi

##logic for enabling micon services all micon
if [ "$has_micon" == "Y" ]; then
   chroot "$target" /bin/bash -c "ln -s /usr/local/bin/micon_scripts/micon_shutdown.py /lib/systemd/system-shutdown/micon_shutdown.py"
   chroot "$target" /bin/bash -c "systemctl enable micon_boot.service" >/dev/null 2>&1
   chroot "$target" /bin/bash -c "systemctl enable micon_fan_daemon.service" >/dev/null 2>&1
else
   if [ "$machine" == "Buffalo Linkstation LS-QL" ]; then
     chroot "$target" /bin/bash -c "ln -s /usr/local/bin/rtc_restart.sh /lib/systemd/system-shutdown/rtc_restart.sh"
   else
     chroot "$target" /bin/bash -c "ln -s /usr/local/bin/phy_restart.sh /lib/systemd/system-shutdown/phy_restart.sh"
   fi
fi

##logic for which kernel? simple enough.
if [ "$arch" == "armhf" ]; then
   cp "../bootshim/armhf_shim" "$target/boot/bootshim"
   if [ "$machine" == "Buffalo Terastation TS3200D" ] || [ "$machine" == "Buffalo Terastation TS3400D" ] || [ "$machine" == "Buffalo Terastation TS3400R" ]; then
      chroot "$target" /bin/bash -c "export FK_IGNORE_EFI=yes; apt-get -y install linux-image-armmp-lpae" >/dev/null 2>&1
   else
      chroot "$target" /bin/bash -c "export FK_IGNORE_EFI=yes; apt-get -y install linux-image-armmp" >/dev/null 2>&1
   fi
   if [ $? -ne 0 ]; then
     echo "kernel install failed"
     exit 99
   fi
fi

##installing my custom kernel on devices that depend on my patches.
if [ "$arch" == "armel" ]; then
   cp "../bootshim/armel_shim" "$target/boot/bootshim"
      chroot "$target" /bin/bash -c "wget -O /etc/apt/custom_repo.gpg https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/KEY.gpg" >/dev/null 2>&1
      chroot "$target" /bin/bash -c "apt-key add /etc/apt/custom_repo.gpg" >/dev/null 2>&1
      echo "deb https://raw.githubusercontent.com/1000001101000/Debian_on_Buffalo/master/PPA/ $distro main" > "$target/etc/apt/sources.list.d/buffalo_kernel.list"
      chroot "$target" /bin/bash -c "apt-get update" >/dev/null 2>&1
      chroot "$target" /bin/bash -c "export FK_IGNORE_EFI=yes; apt-get -y install linux-image-marvell-buffalo" >/dev/null 2>&1
   if [ $? -ne 0 ]; then
     echo "kernel install failed"
     exit 99
   fi
fi

rm "$target/etc/flash-kernel/machine"

echo "disk image ready for use"

umount_stop_temp_devs
