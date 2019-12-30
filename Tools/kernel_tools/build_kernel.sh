#!/bin/bash

kernel_ver="$1"
rm *.deb
rm *.changes

cd linux-source-$kernel_ver
cp  ../configs/custom-config-$kernel_ver .config
make oldconfig ARCH=arm
make -j$(nproc) ARCH=arm KBUILD_DEBARCH=armel CROSS_COMPILE="arm-linux-gnueabi-" bindeb-pkg
