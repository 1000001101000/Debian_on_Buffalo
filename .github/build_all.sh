#!/bin/bash

scripts="$(find . | grep generate_images | xargs -n 1 dirname | sort -u)"
archs="armhf armel"
oldpwd="$PWD"

for x in $scripts
do
  cd "$x"
#  echo $PWD; exit
  for arch in $archs
  do
    rm ${arch}-files/* 2>/dev/null
    ./generate_images_${arch}.sh
    mkdir ../${arch}_devices 2>/dev/null
    cp -v output/initrd.buffalo.$arch ../${arch}_devices/initrd.buffalo
    cp -v output/uImage*buffalo.* ../${arch}_devices/
    cat ${arch}-files/initrd.gz | md5sum > last_build_${arch}.txt
  done
  cd "$oldpwd"
done
