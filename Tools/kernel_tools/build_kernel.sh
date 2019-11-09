#!/bin/bash
## download from https://releases.linaro.org/components/toolchain/binaries/
prefix="/usr/local/bin/distcc/gcc-linaro-7.4.1-2019.02-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-"

kernel_ver="$1"
rm *.deb
rm *.changes

cd linux-source-$kernel_ver
cp  ../configs/custom-config-$kernel_ver .config
make oldconfig ARCH=arm
make -j$(nproc) ARCH=arm KBUILD_DEBARCH=armel CROSS_COMPILE="$prefix" bindeb-pkg

cd ..

exit 0


