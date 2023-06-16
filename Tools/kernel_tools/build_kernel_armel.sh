#!/bin/bash

kernel_ver="$1"
pkg_version="$2"

rm *.deb
rm *.changes

config="$(ls configs | grep $kernel_ver | grep marvell | sort | tail -n 1)"
if [ "$config" == "" ]; then
   echo "source config not found, quitting"
   exit 99
fi
echo $config

cd linux-source-$kernel_ver
cp  ../configs/$config .config
cat ../custom_configs_armel >> .config
echo "$pkg_version" > .version

##debootstrap won't run for SUBLEVEL>=255 for fear of libc bugs or something
##not sure if these bugs still exist in the wild or not.
##when needed make a .254 version based on whatever is current for the installer.
#sl="$(head -n 10 Makefile | grep -e ^SUBLEVEL.*$ | cut -d " " -f 3)"
#if [ $sl -gt 254 ]; then
#  sed -i 's/^SUBLEVEL.*$/SUBLEVEL = 254/g' Makefile
#fi

make olddefconfig ARCH=arm
make -j$(nproc) ARCH=arm KBUILD_DEBARCH=armel CROSS_COMPILE="arm-linux-gnueabi-" bindeb-pkg
rm *.buildinfo
