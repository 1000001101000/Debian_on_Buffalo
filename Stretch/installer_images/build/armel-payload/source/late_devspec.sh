##special stuff for terastation
grep Teras /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
	cp -r /source/micon_scripts "/target/usr/local/bin/"
	cp /source/micon_scripts/*.service /target/etc/systemd/system/
	cp /source/micon_scripts/micon_restart.sh /target/lib/systemd/system-shutdown/
        chmod 755 /target/lib/systemd/system-shutdown/micon_restart.sh
fi

exit 0
