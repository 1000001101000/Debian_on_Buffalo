#!/bin/bash

kernel_ver="$1"
pkg_version="$2"

rm *.deb
rm *.changes

config="$(ls configs | grep $kernel_ver | grep marvell | sort | tail -n 1)"
echo $config

cd linux-source-$kernel_ver
cp  ../configs/$config .config
cat ../custom_configs_armel >> .config
echo "$pkg_version" > .version
make olddefconfig ARCH=arm
make -j$(nproc) ARCH=arm KBUILD_DEBARCH=armel CROSS_COMPILE="arm-linux-gnueabi-" bindeb-pkg
