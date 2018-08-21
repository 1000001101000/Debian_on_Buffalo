# Debian_on_Buffalo
Tools for Installing/Running Debian on Buffalo Linkstation/Terastation (LS4XX, LS2XX, TS1400 etc) 


Some great work has been done over the past few years to run modern Debian Linux on the more recent Buffalo Linkstation models, most notably the LS421DE. I've spent some time over the past year building off of that work with the goal of simplifying the process to make it more like a typical Debian install, most notably by using the ARMHF kernel provided by Debian rather than cross compiling a custom one.


- Use the Vanilla Debian Kernel, removing the need to compile your own.
- Use Flash-Kernel to automate the generation of new Kernel/Initrd images. (allow kernel updates without any manual steps)
- Use the Debian installer to setup the base system 
- Support RAID1 boot and rootfs devices to allow hotswapping drives.
- Support additional devices (LS210, LS420, LS421, LS441, TS1400D and TS1400R Tested so far)

I'm confident this can be made to work on the LS220, LS410 and TS1200 as well but I have not had access to them to test with yet. 

My goal is that someone with fairly basic Linux skills will be able to do this using the tools provided by Debian and as few files/resources provided by me as possible.

The basic process is as follows:

1. Download the Debian network-console installer files (vmlinuz and initrd.gz) from Debian's site
2. Download the corresponding device tree file for your device from this site
3. Append the device tree to the kernel file.
4. Package the Kernel and initrd as uBoot images using mkimage.
5. Prepare the boot disk(s) by creating an ext3 partition to boot from.
6. copy the images over to the disk as uImage.buffalo and initrd.buffalo 
7. Insert the disk(s) and boot the device.
8. Connect to the device via ssh and run through the typicall installer steps (set timezone, partition disks, etc)
9. Before rebooting, open a shell and:
   a. install flash-image
   b. add entries for the buffalo devices under /usr/share/flash-kernel/db
   c. add the DTB file for the device under /etc/flash-kernel/dtb
   d. run flash-kernel to generate appropriate kernel and inird images
   e. add the correct MAC address to /etc/network/interfaces
10. Reboot 
11. Connect to device over ssh, verify that /etc/fstab and /etc/mdadm/mdadm.conf make sense, adjust if needed.

I'll expand on all of this as I build out the repository

