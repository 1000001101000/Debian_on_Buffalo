#!/bin/bash

kernel_ver="$1"

##run as root/sudo
apt-get update
apt-get install linux-source-$kernel_ver

rm -r linux-source-$kernel_ver/ 2> /dev/null
tar xf /usr/src/linux-source-$kernel_ver.tar.xz
if [ "$?" -ne 0 ]; then
   exit 1
fi

user="$(ls -la . | grep -e ^d | head -n 1 | gawk '{print $3}')"
group="$(ls -la . | grep -e ^d | head -n 1 | gawk '{print $4}')"

cd linux-source-$kernel_ver
for patch in $(ls ../patches/$kernel_ver)
do
  patch -p1 < ../patches/$kernel_ver/$patch
done
for patch in $(ls ../patches/default)
do
  patch -p1 < ../patches/default/$patch
done


cd ..
chown -R $user:$group linux-source-$kernel_ver
