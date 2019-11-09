#!/bin/bash

kernel_ver="$1"

##run as root/sudo
apt-get update
apt-get install linux-source-$kernel_ver

rm -r linux-source-$kernel_ver/
rm -r vanilla-source-$kernel_ver/
tar xf /usr/src/linux-source-$kernel_ver.tar.xz
cp -r linux-source-$kernel_ver/ vanilla-source-$kernel_ver

user="$(ls -la . | grep -e ^d | head -n 1 | gawk '{print $3}')"
group="$(ls -la . | grep -e ^d | head -n 1 | gawk '{print $4}')"

cd linux-source-$kernel_ver
for patch in $(ls ../patches/$kernel_ver)
do
  patch -p1 < ../patches/$kernel_ver/$patch
done
cd ..

chown -R $user:$group linux-source-$kernel_ver
chown -R $user:$group vanilla-source-$kernel_ver
