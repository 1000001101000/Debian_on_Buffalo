run_size="$(busybox df -m /run | busybox tail -n 1 | busybox awk '{print $2}')"

mount -o remount,nosuid,noexec,size=26M,nr_inodes=4096 /run
