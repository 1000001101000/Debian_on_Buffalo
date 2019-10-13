##special stuff for devices with microcontroller
if [ "$(/source/micro-evtd -s 0003 | tail -n 1)" == "0" ]; then
	cp -r /source/micon_scripts "/target/usr/local/bin/"
	cp /source/micon_scripts/*.service /target/etc/systemd/system/
	cp /source/micon_scripts/micon_shutdown.py /target/lib/systemd/system-shutdown/
        chmod 755 /target/lib/systemd/system-shutdown/micon_shutdown.py
fi

machine=`sed -n '/Hardware/ {s/^Hardware\s*:\s//;p}' /proc/cpuinfo`
case $machine in
	*"(Flattened Device Tree)")
	machine=$(cat /proc/device-tree/model)
	;;
esac
case $machine in
	"Buffalo Linkstation Pro/Live" | "Buffalo/Revogear Kurobox Pro")
	echo "/dev/mtdblock1 0x00000 0x10000 0x10000" > /target/etc/fw_env.config ;;
	"Buffalo Terastation Pro II/Live")
	echo "/dev/mtdblock0 0x0003f000 0x1000 0x1000" > /target/etc/fw_env.config ;;
	*)
	echo "/dev/mtdblock1 0x00000 0x10000 0x10000" > /target/etc/fw_env.config ;;
esac

exit 0
