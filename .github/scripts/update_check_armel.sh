#!/bin/bash

distros="Stretch Buster"
svpwd="$(pwd)"

for distro in $distros
do
  curl "http://ftp.nl.debian.org/debian/dists/$distro/main/installer-armel/current/images/kirkwood/netboot/initrd.gz" 2>/dev/null | md5sum > /tmp/latest.txt
  diff /tmp/latest.txt $distro/installer_images/build/last_build_armel.txt 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "image is up to date"
    continue
  else
    cd $distro/installer_images/build/
    ./generate_images_armel.sh
  fi
  if [ $? -eq 0 ]; then
    echo "copy to proper dir"
    cp -v output/initrd.buffalo.armel ../armel_devices/initrd.buffalo
    cp -v output/uImage*buffalo.* ../armel_devices/
    cp -v output/vmlinuz-armel ../armel_devices/vmlinuz
    cp "/tmp/latest.txt" "last_build_armel.txt"
    git commit -a -m "generate images based on latest debian installer" 
    #echo "::set-output name=commit_needed::yes"
  fi
  cd "$svpwd"
done
exit 0
