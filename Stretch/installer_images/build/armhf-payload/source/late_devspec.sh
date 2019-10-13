##special stuff for ts3000
grep TS3 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
	cp -r /source/micon_scripts "/target/usr/local/bin/"
	cp /source/micon_scripts/*.service /target/etc/systemd/system/
	cp /source/micon_scripts/micon_restart.sh /target/lib/systemd/system-shutdown/
        chmod 755 /target/lib/systemd/system-shutdown/micon_restart.sh
fi

grep TS14 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
        cp -r /source/micon_scripts "/target/usr/local/bin/"
        cp /source/micon_scripts/*.service /target/etc/systemd/system/
	cp /source/micon_scripts/micon_restart.sh /target/lib/systemd/system-shutdown/
        chmod 755 /target/lib/systemd/system-shutdown/micon_restart.sh
fi

grep LS4 /proc/device-tree/model > /dev/null
is_ls400=$?
grep TS12 /proc/device-tree/model > /dev/null
is_ts1200=$?
if [ $is_ls400 -eq 0 ] || [ $is_ts1200 -eq 0 ]; then
      cp /source/phy_restart.sh /target/lib/systemd/system-shutdown/
      chmod 755 /target/lib/systemd/system-shutdown/phy_restart.sh
fi

exit 0
