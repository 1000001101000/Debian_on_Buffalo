#!/bin/bash

distros="Stretch Buster"
svpwd="$(pwd)"

for distro in $distros
do
  curl "http://ftp.debian.org/debian/dists/$distro/main/installer-armhf/current/images/network-console/initrd.gz" 2>/dev/null | md5sum > /tmp/latest.txt
  diff /tmp/latest.txt $distro/installer_images/build/last_build_armhf.txt 2>/dev/null
  if [ $? -eq 0 ]; then
    echo "image is up to date"
    continue
  else
    cd $distro/installer_images/build/
    echo $(pwd)
    ./generate_images_armhf.sh
  fi
  if [ $? -eq 0 ]; then
    echo "copy to proper dir"
    #cp "/tmp/latest.txt" "last_build.txt"
    #git commit -a -m "generate images based on latest debian installer" 
    #echo "::set-output name=commit_needed::yes"
  fi
  cd "$svpwd"
done
exit 0
