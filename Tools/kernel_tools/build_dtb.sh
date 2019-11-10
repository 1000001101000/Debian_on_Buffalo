#!/bin/bash
## download from https://releases.linaro.org/components/toolchain/binaries/
prefix="/usr/local/bin/distcc/gcc-linaro-7.4.1-2019.02-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-"

kernel_ver="$1"

mkdir -p dts/$kernel_ver
mkdir -p dtb/$kernel_ver

dtbs="$(ls dts/$kernel_ver | grep .dts | sed 's/dts/dtb/g')"

cd linux-source-$kernel_ver
cp  ../configs/custom-config-$kernel_ver .config

rm ../dtb/$kernel_ver/*.dtb 2>/dev/null
rm arch/arm/boot/dts/*.dtb 2>/dev/null
cp ../dts/$kernel_ver/*.dts arch/arm/boot/dts/
cp arch/arm/boot/dts/Makefile arch/arm/boot/dts/Makefile.old
echo 'dtb-y="'$dtbs'"' > arch/arm/boot/dts/Makefile
#tail -n 4 arch/arm/boot/dts/Makefile.old >> arch/arm/boot/dts/Makefile

make -j$(nproc) ARCH=arm CROSS_COMPILE="$prefix" $dtbs
cp arch/arm/boot/dts/*.dtb ../dtb/$kernel_ver/
mv arch/arm/boot/dts/Makefile.old arch/arm/boot/dts/Makefile
