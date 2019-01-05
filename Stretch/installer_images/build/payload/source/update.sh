mount /dev/sda2 /mnt                                                                                         
mount /dev/sda1 /mnt/boot                                           
chroot /mnt /bin/bash -c "/usr/bin/scp jeremy@earth:~/repo/Debian_on_Buffalo/Stretch/installer_images/build/*.buffalo /boot/"
