#!/bin/bash

. ./functions.sh

target="./.buildtmp"
target_hostname="debian"
machine="Buffalo Linkstation LS220D"
target_user="debian"
default_distro="trixie"
boot_size="512"  ## could add sanity check, could prompt with defaults
swap_size="512"
root_size="2048"
use_raid="Y"
mirror="http://deb.debian.org/debian"

##packages added to deal with distro-specific issues which may not all be required
packages="busybox,libpam-systemd,dbus,bsdextrautils,binutils,debconf,locales,systemd-timesyncd"

###technically only needed if doing software raid, logical default for nas OS
packages="$packages,mdadm"

###stuff I would install anyway but is depended on for the install script specifically
packages="$packages,uuid-runtime,libarchive-tools,gdisk,wget"

##needed for micon scripts
packages="$packages,python3,python3-serial"

##specifically for rtc_restart, useful for low level hardward poking
packages="$packages,i2c-tools"

##needed for devices with strict initrd size limits to generate smallest possible initrd, useful to have regardless
packages="$packages,xz-utils"

###needed for all devices booting uboot
packages="$packages,flash-kernel,u-boot-tools"

###ssh-server, could replace with dropbear to be more lightweight.
packages="$packages,openssh-server,haveged"

###needed for custom repo, probably other uses too.
packages="$packages,apt-transport-https,gnupg,ca-certificates"

##install manually ahead of kernel install to avoid some debconf issues
packages="$packages,apparmor"

##check for required tools
for x in debootstrap dd gawk grep chroot pwd date tee wget
do
  which "$x" > /dev/null
  if [ $? -ne 0 ]; then
    echo "$x not found in PATH, please install or adjust PATH and try again"
    exit 99
  fi
done

##prompt for machine name
read -r -p "Enter model string [$machine]: " tmpmachine
[ -z "$tmpmachine" ] || machine="$tmpmachine"

arch=""
has_micon="N"
case $machine in
  "Buffalo Terastation TS1400D"|"Buffalo Terastation TS1400R"|"Buffalo Terastation TS3200D"|"Buffalo Terastation TS3400D"|"Buffalo Terastation TS3400R")
    has_micon="Y"
    arch="armhf"
    ;;
  "Buffalo Linkstation LS210D"|"Buffalo Linkstation LS410D")
    use_raid="N"
    arch="armhf"
    ;;
  "Buffalo Terastation TS1200D"|"Buffalo Linkstation LS220D"|"Buffalo Linkstation LS420D"|"Buffalo Linkstation LS421D"|"Buffalo Linkstation LS441D")
    arch="armhf"
    ;;
  "Buffalo Terastation Pro II/Live"|"Buffalo Terastation TS-XEL"|"Buffalo Nas WXL"|"Buffalo Terastation III")
    has_micon="Y"
    arch="armel"
    ###needs ext3 inode size, hybridgpt
    ;;
  "Buffalo Linkstation Pro/Live"|"Buffalo/Revogear Kurobox Pro")
    has_micon="Y"
    arch="armel"
    ###needs ext3 inode size, hybridgpt
    ;;
  "Buffalo Linkstation LS-XL"|"Buffalo Linkstation LS-VL"|"Buffalo Linkstation LS-CHLv2"|"Buffalo Linkstation LS-XHL"|"Buffalo Linkstation LiveV3 (LS-CHL)")
    arch="armel"
    use_raid="N"
    ;;
  "Buffalo Linkstation LS-WXL"|"Buffalo Linkstation LS-WVL"|"Buffalo Linkstation LS-WSXL"|"Buffalo Linkstation Mini (LS-WSGL)"|"Buffalo Linkstation Mini"|"Buffalo Linkstation LS-WTGL")
    arch="armel"
    ;;
  "Buffalo Linkstation LS-QL"|"Buffalo Linkstation LS-QVL")
    arch="armel"
    ###need trim disabled
    ###ql also needs inode size
    ;;
esac

if [ "$arch" == "" ]; then
   echo "Machine ID didn't match a supported model!"
   exit 1
fi

##check for qemu support for the architecture
which "qemu-system-$arch" > /dev/null
if [ $? -ne 0 ]; then
  echo "qemu-system-$arch not found in PATH, please install or adjust PATH and try again"
  exit 99
fi

##prompt for machine name
distro="$default_distro"
read -r -p "Enter debian version [$distro]: " tmpdistro
[ -z "$tmpdistro" ] || distro="$tmpdistro"

log="debian_""$distro""_""$arch"".log"

##check for suitable release file
for x in "$mirror" "https://archive.debian.org/debian"
do
  mirror=""
  release="$x/dists/$distro/main/binary-$arch/Release"
  wget -O /dev/null "$release" >>"$log" 2>&1 && mirror="$x" && break
done

[ -z "$mirror" ] && echo "binary-$arch release file for $distro not found" && exit 99

##attempt to determine user running script and whether they have ssh pubkey handy.
pid=$PPID
for x in 1 2 3
do
  puser="$(ps -o uname= -p $pid)"
  if [ "$puser" != "root" ]; then
    sshkey="/home/$puser/.ssh/id_rsa.pub"
    break
  fi
  pid=`grep -e "^PPid:" /proc/$pid/status | gawk '{print $2}'`
done

##prompt for passwords rather than sticking them in the script
read -p "Enter default username [$target_user]: " tmpuser
[ -z "$tmpuser" ] || target_user="$tmpuser"
read -s -p "Enter password: " target_userpw
echo
read -s -p "Repeat password: " tmp
echo
[ "$target_userpw" != "$tmp" ] && echo "passwords did not match" && exit 99

##prompt for root password
read -s -p "Enter root password: " target_rootpw
echo
read -s -p "Repeat root password: " tmp
echo
[ "$target_rootpw" != "$tmp" ] && echo "passwords did not match" && exit 99

if [ -f "$sshkey" ]; then
  read -p "install $sshkey to allow passwordless root ssh logins? [N,y]: " ans
  [ "${ans^^}" != "Y" ] && sshkey=""
fi

read -p "Enter desired hostname [$target_hostname]: " tmp_hostname
[ -z "$tmp_hostname" ] || target_hostname=tmp_hostname

read -p "Setup system partitions for RAID? [$use_raid]: " tmpraid
[ -z "$tmpraid" ] || use_raid="${tmpraid^^}"

image_name="debian_""$distro""_""$arch"".img"
[ -e "$image_name" ] && rm -v "$image_name"

echo "Process started, logging output to "$log"" | tee "$log"

[ -d "$target" ] && rm -r "$target"
mkdir -p "$target/boot"
if [ $? -ne 0 ]; then echo "failed to create working directory: $target/boot" ; exit 99; fi

qemu_path="$(which qemu-system-$arch)"
if [ $? -ne 0 ]; then
  echo "qemu-system-$arch not found, install binfmt-support or equivalent"
  exit 99
fi

if [ "$distro" == "stretch" ] ||  [ "$distro" == "buster" ]; then
  for x in systemd-timesyncd bsdextrautils
  do
    packages=`echo $packages | sed "s/$x//g"`
  done
fi

echo "running debootstrap" | tee -a "$log"
debootstrap --arch "$arch" --include="$packages" "$distro" "$target" "$mirror" | tee -a "$log"

#add prereq for qemu, not needed or already handled by deboostrap these days
cp "$qemu_path" "$target/usr/bin/"
if [ $? -ne 0 ]; then
  echo "failed to setup qemu chroot"
  exit 99
fi

chroot "$target" ls >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "unable to run chroot, qemu issue?"
  exit 99
fi

bootID="$(uuidgen_chroot)"
rootID="$(uuidgen_chroot)"
swapID="$(uuidgen_chroot)"

##devices with sata port expanders can't handle trim() commands.
##not an issue for most cases but causes havoc if testing with ssd
##try to disable those commands to prevent issues for that case
##generate fstab
echo -e "UUID=$rootID\t/\text4\terrors=remount-ro,nodiscard\t0\t1" >> "$target/etc/fstab"
echo -e "UUID=$bootID\t/boot\text3\tdefaults,nodiscard\t0\t2" >> "$target/etc/fstab"
echo -e "UUID=$swapID\tnone\tswap\tsw,nodiscard\t0\t0" >> "$target/etc/fstab"

echo "fstab built" | tee -a "$log"

echo "auto lo" >> "$target/etc/network/interfaces"
echo "iface lo inet loopback" >> "$target/etc/network/interfaces"
echo "" >> "$target/etc/network/interfaces"
echo "allow-hotplug eth0" >> "$target/etc/network/interfaces"
echo "iface eth0 inet dhcp" >> "$target/etc/network/interfaces"

echo "network configuration created" | tee -a "$log"

echo "$target_hostname" > "$target/etc/hostname" && echo "hostname set" | tee -a "$log"

##my customizations micon/etc
mkdir -p "$target/usr/local/bin/micon_scripts"
for x in libmicon.py micon_fan_daemon.py micon_shutdown.py micon_startup.py
do
  gh_download_chroot "Tools/micon_scripts/$x" "/usr/local/bin/micon_scripts/$x"
done
chmod 755 "$target"/usr/local/bin/micon_scripts/*.py
gh_download_chroot "Tools/micon_scripts/micon_boot.service" "/etc/systemd/system/micon_boot.service"
gh_download_chroot "Tools/micon_scripts/micon_fan_daemon.service" "/etc/systemd/system/micon_fan_daemon.service"

gh_download_chroot "Tools/micro-evtd-$arch" "/usr/local/bin/micro-evtd"
gh_download_chroot "Tools/phytool-$arch" "/usr/local/bin/phytool"
gh_download_chroot "Tools/phy_restart.sh" "/usr/local/bin/phy_restart.sh"
gh_download_chroot "Tools/rtc_restart.sh" "/usr/local/bin/rtc_restart.sh"
chmod 755 "$target"/usr/local/bin/*

##boot shim and hook script
echo "setup bootshim" | tee -a "$log"
gh_download_chroot "Tools/bootshim/$arch\_shim" "/boot/bootshim"
gh_download_chroot "Tools/0-install_shim" "/etc/initramfs/post-update.d/0-install_shim"
chmod +x "$target/etc/initramfs/post-update.d/0-install_shim"

##flash-kernel setup
echo "configuring flash-kernel" | tee -a "$log"
gh_download_chroot "Tools/0-buffalo_devices.db" "/usr/share/flash-kernel/db/0-buffalo_devices.db"
echo yes > "$target/etc/flash-kernel/ignore-efi"
echo "$machine" > "$target/etc/flash-kernel/machine"

##at this point armel has dtbs in the kernel package, install the needed one for armhf devices
##could use some work for historical/alternate dtbs
if [ "$arch" == "armhf" ]; then
  echo "installing device-tree" | tee -a "$log"
  search="^Machine: $machine"
  dtb=`grep -A 4 -e "$search" "$target/usr/share/flash-kernel/db/0-buffalo_devices.db" | grep DTB-Id | gawk '{print $2}'`
  gh_download_chroot "${default_distro^}/device_trees/$dtb" "/etc/flash-kernel/dtbs/$dtb"
fi

##initrd hooks/config for sure.
echo "COMPRESS=xz"    > "$target/usr/share/initramfs-tools/conf.d/compress"
echo "XZ_OPT=-2e"    >> "$target/usr/share/initramfs-tools/conf.d/compress"
echo "export XZ_OPT" >> "$target/usr/share/initramfs-tools/conf.d/compress"
echo "BOOT=local" > "$target/usr/share/initramfs-tools/conf.d/localboot"
echo "MODULES=list" > "$target/etc/initramfs-tools/conf.d/modules"
echo "RESUME=none" > "$target/etc/initramfs-tools/conf.d/resume" # suppresses the message as none of these support hibernate, though mostly for lack of it being implemented in kernel
echo "FSTYPE=ext4" > "$target/etc/initramfs-tools/conf.d/root" ## still needed?
echo "RUNSIZE=$((26*1024*1024))" > "$target/etc/initramfs-tools/conf.d/runsize"

###is it worth trying to trim any of these? of part for sure, possibly libcrc,autofs4 not much really
for module in sata_mv libata ahci libahci crypto-crc32c jbd2 mbcache crc16 ext4 autofs4 crc32c_generic sd_mod sg scsi_common scsi_mod libcrc32c
do
  echo "$module" >> "$target/etc/initramfs-tools/modules"
done

echo "custom files/scripts copied" | tee -a "$log"

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
chroot "$target" "/users.sh" >>"$log" 2>&1
if [ $? -ne 0 ]; then
  echo "user setup failed"
  exit 99
fi
rm "$target/users.sh"

if [ -f "$sshkey" ]; then
  echo "installing sshkey as requested"
  mkdir -p "$target/root/.ssh/"
  cat "$sshkey" >> "$target/root/.ssh/authorized_keys"
fi

echo "user setup complete" | tee -a "$log"

##setup fw_printenv. breaks easily, probably move to dynamic at start...or just omit.
if [ "$arch" == "armhf" ]; then
  echo '/dev/mtdblock1 0x00000 0x10000 0x10000' > "$target/etc/fw_env.config"
fi

##logic for enabling micon services all micon
if [ "$has_micon" == "Y" ]; then
   chroot "$target" /bin/bash -c "ln -s /usr/local/bin/micon_scripts/micon_shutdown.py /lib/systemd/system-shutdown/micon_shutdown.py"
   chroot "$target" /bin/bash -c "systemctl enable micon_boot.service" >>"$log" 2>&1
   chroot "$target" /bin/bash -c "systemctl enable micon_fan_daemon.service" >>"$log" 2>&1
else
   if [ "$machine" == "Buffalo Linkstation LS-QL" ]; then
     chroot "$target" /bin/bash -c "ln -s /usr/local/bin/rtc_restart.sh /lib/systemd/system-shutdown/rtc_restart.sh"
   else
     chroot "$target" /bin/bash -c "ln -s /usr/local/bin/phy_restart.sh /lib/systemd/system-shutdown/phy_restart.sh"
   fi
fi

echo "creating disk image" | tee -a "$log"
chroot "$target" /bin/bash -c "dd if=/dev/zero of=$image_name bs=1M count=$((1+boot_size+1+swap_size+1+root_size+2))" >>"$log" 2>&1
if [ $? -ne 0 ]; then
  echo "failed to create empty disk image"
  exit 99
fi

##create partitions in disk image along with an extra 1M for mdadm/alignment
chroot "$target" /bin/bash -c "sgdisk -n 1:0:+$((boot_size+1))M $image_name" >>"$log" 2>&1
if [ $? -ne 0 ]; then
  echo "failed to create boot partition"
  exit 99
fi

chroot "$target" /bin/bash -c "sgdisk -n 2:0:+$((swap_size+1))M $image_name" >>"$log" 2>&1
if [ $? -ne 0 ]; then
  echo "failed to create swap partition"
  exit 99
fi

chroot "$target" /bin/bash -c "sgdisk -n 3:0 $image_name" >>"$log" 2>&1
if [ $? -ne 0 ]; then
  echo "failed to create root partition"
  exit 99
fi

###this stuff into chroot, think there's one in the mdadm bit too.
#get sector size of partition table, should always be 512
sectorsz=`chroot "$target" /bin/bash -c "sgdisk -p $image_name" | grep 'Sector size (logical):' | gawk '{print $4}'`

#get starting sector for boot, should be 2048
bootstart=`chroot "$target" /bin/bash -c "sgdisk -i 1 $image_name" | grep 'First sector:' | gawk '{print $3}'`

#get starting sector for swap
swapstart=`chroot "$target" /bin/bash -c "sgdisk -i 2 $image_name" | grep 'First sector:' | gawk '{print $3}'`

#get starting sector for rootfs
rootstart=`chroot "$target" /bin/bash -c "sgdisk -i 3 $image_name" | grep 'First sector:' | gawk '{print $3}'`

if [ "$use_raid" == "Y" ]; then
  echo "configuring raid devices" | tee -a "$log"
  mkdir -p "$target"/etc/mdadm/  ##probably already there from package
  for x in 1 2 3
  do
    tmpuuid=$(uuidgen_chroot)
    raidstart=`chroot "$target" /bin/bash -c "sgdisk -i $x $image_name" | grep 'First sector:' | gawk '{print $3}'`
    raidstart=$((raidstart*sectorsz))
    raidsize=`chroot "$target" /bin/bash -c "sgdisk -i $x $image_name" | grep 'Partition size:'| gawk '{print $3}'`
    raidsize=$(( (raidsize*sectorsz) & 0xFFFF0000 ))
    gen_raid1_sb "$x" "$tmpuuid" "$raidsize" >>"$log" 2>&1
    mv "tmpsb.bin" "$target"
    chroot "$target" /bin/bash -c "mdadm -E tmpsb.bin" >>"$log" 2>&1
    if [ $? -ne 0 ]; then
      echo "failed to generate md superblock for partition $x"
      exit 99
    fi
    chroot "$target" /bin/bash -c "dd if=tmpsb.bin of=$image_name bs=64k count=1 seek=$(( (raidstart + raidsize) - (64*1024) )) oflag=seek_bytes conv=notrunc" >>"$log" 2>&1
    if [ $? -ne 0 ]; then
      echo "failed to write md superblock to partition $x"
      exit 99
    fi
    chroot "$target" /bin/bash -c "sgdisk -t $x:FD00 $image_name" >>"$log" 2>&1
    if [ $? -ne 0 ]; then
      echo "failed to set partition type"
      exit 99
    fi
    echo "ARRAY /dev/md/md$((x-1)) metadata=0.90 name=$target_hostname:md$((x-1)) UUID=$tmpuuid" >> "$target/etc/mdadm/mdadm.conf"
    rm "$target/tmpsb.bin"
  done
else
  ## for non raid set type to either linux filesystem or linux swap
  chroot "$target" /bin/bash -c "sgdisk -t 1:8300 $image_name" >>"$log" 2>&1
  if [ $? -ne 0 ]; then
    echo "failed to set partition type"
    exit 99
  fi
  chroot "$target" /bin/bash -c "sgdisk -t 2:8200 $image_name" >>"$log" 2>&1
  if [ $? -ne 0 ]; then
    echo "failed to set partition type"
    exit 99
  fi
  chroot "$target" /bin/bash -c "sgdisk -t 3:8300 $image_name" >>"$log" 2>&1
  if [ $? -ne 0 ]; then
    echo "failed to set partition type"
    exit 99
  fi
fi

##make hybrid gpt if certain devices specified.
if [ "$arch" == "armel" ]; then
  echo "creating hybrid GPT/MBR record to support booting large disks" | tee -a "$log"
  chroot "$target" /bin/bash -c "sgdisk -h 1:EE $image_name" >>"$log" 2>&1
  if [ $? -ne 0 ]; then
    echo "failed to create hybrid GPT/MBR record, image may not be bootable"
    exit 99
  fi
fi

kernel=""
if [ "$arch" == "armhf" ]; then
   if [ "$machine" == "Buffalo Terastation TS3200D" ] || [ "$machine" == "Buffalo Terastation TS3400D" ] || [ "$machine" == "Buffalo Terastation TS3400R" ]; then
      kernel="linux-image-armmp-lpae" >>"$log" 2>&1
   else
      kernel="linux-image-armmp" >>"$log" 2>&1
   fi
fi

##installing my custom kernel on devices that depend on my patches.
if [ "$arch" == "armel" ]; then
   echo "configuring custom kernel repo" | tee -a "$log"
   sources_file="$target/etc/apt/sources.list.d/buffalo_kernel.sources"
   echo "Types: deb" > "$sources_file"
   echo "URIs: $gh_url/PPA/" >> "$sources_file"
   echo "Suites: $distro" >> "$sources_file"
   echo "Components: main" >> "$sources_file"
   echo "Signed-By: /usr/share/keyrings/buffalo_kernel.gpg" >> "$sources_file"
   gh_download_chroot "PPA/KEY.gpg" "/usr/share/keyrings/buffalo_kernel.gpg"
   chroot "$target" /bin/bash -c "apt-get update" >>"$log" 2>&1
   if [ $? -ne 0 ]; then
     echo "custom kernel repo setup failed"
     exit 99
   fi
   kernel="linux-image-marvell-buffalo"
fi

echo "installing kernel" | tee -a "$log"
##flash-kernel hook will complain about rootdev not being present, DEBIAN_HAS_FRONTEND prevents it stopping at a prompt
chroot "$target" /bin/bash -c "DEBIAN_HAS_FRONTEND=y apt-get -y install $kernel" >>"$log" 2>&1
if [ $? -ne 0 ]; then
 echo "kernel install failed"
 exit 99
fi

##disable fstrim, it's not safe for some devices and pointless for most use cases on these devices.
##might narrow it down to just where it breaks stuff later on...that might be a moving target though.
if [ "$arch" == "armel" ]; then
  echo "disabling fstrim service" | tee -a "$log"
  chroot "$target" /bin/bash -c "systemctl disable fstrim.timer" >>"$log" 2>&1
  chroot "$target" /bin/bash -c "systemctl disable fstrim.service" >>"$log" 2>&1
fi

##counting on the system determining this dynamically going forward
rm "$target/etc/flash-kernel/machine"

##allow smaller initrd with less modules after first boot
echo "MODULES=dep" > "$target/etc/initramfs-tools/conf.d/modules"

##set inode size for older devices that require older inode format
bootflag=""
[ "$arch" == "armel" ] && bootflag="-I 128"

echo "writing boot filesystem"
chroot "$target" /bin/bash -c "mkfs.ext3 -F $bootflag -U $bootID -d /boot -E offset=$((sectorsz*bootstart)) $image_name ${boot_size}M" >>"$log" 2>&1
if [ $? -ne 0 ]; then echo "write boot image failed"; exit 92; fi

##empty out the boot mountpoint for a clean image
chroot "$target" /bin/bash -c "rm -r ./boot/*"

###write rootfs into image
echo "writing root filesystem" | tee -a "$log"
chroot "$target" /bin/bash -c "tar --exclude=./$image_name -cf - . | mkfs.ext4 -F -U $rootID -d - -E offset=$((sectorsz*rootstart)) $image_name ${root_size}M" >>"$log" 2>&1
if [ $? -ne 0 ]; then echo "write root image failed"; exit 91; fi

echo "writing swap" | tee -a "$log"
chroot "$target" /bin/bash -c "mkswap -o $((sectorsz*swapstart)) -U $swapID $image_name $((swap_size*1024))" >>"$log" 2>&1
if [ $? -ne 0 ]; then echo "write swap image failed"; exit 91; fi

echo "performing cleanup" | tee -a "$log"

##move to pwd
mv "$target/$image_name" .

rm -r "$target"

echo "disk image ready for use" | tee -a "$log"
