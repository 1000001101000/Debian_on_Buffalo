opts="CONFIG_RTC_DRV_RS5C372=m"
modules="rtc-rs5c372"
kernels="$(ls /lib/modules)"

for kernel in $kernels
do
    for module in $modules
    do
        find /lib/modules/$kernel/ | grep $module.ko > /dev/null
        if [ $? -eq 0 ]; then
            continue
        fi
        k_ver="$(echo $kernel | cut -d'.' -f1-2)"
        k_ver_long="$(echo $kernel | cut -d'-' -f1-2)"
        apt-get install linux-headers-$kernel linux-source-$k_ver linux-headers-$k_ver_long-common ##> /dev/null
        cd /usr/src
        cp -rf linux-headers-$kernel build-temp-$kernel
        cd build-temp-$kernel
        cp -rf ../linux-headers-$k_ver_long-common/* .
        src_path="$(tar tf ../linux-source-$k_ver.tar.xz | grep $module)"
	src_dir="$(dirname $src_path)"
        tar xvf ../linux-source-$k_ver.tar.xz --wildcards --strip-components=1 $src_dir/*
        src_dir="${src_dir#*/}"
        make M="$src_dir" $opts
        cp -v $src_dir/$module.ko /lib/modules/$kernel/kernel/
        insmod /lib/modules/$kernel/kernel/$module.ko
    done
    depmod -a
done
