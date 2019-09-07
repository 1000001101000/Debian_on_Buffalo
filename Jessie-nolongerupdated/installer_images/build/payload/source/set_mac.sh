ip link set dev "$1" down
sleep 2
ip link set dev "$1" address "$2"
sleep 2
ip link set dev "$1" up
