##special stuff for ts3000
grep TS3 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
	cp -r /source/ts3000_scripts "/target/usr/local/bin/"
	cp /source/ts3000_scripts/*.service /target/etc/systemd/system/
	cp /source/ts3000_scripts/ts3000_restart.sh /target/lib/systemd/system-shutdown/
        chmod 755 /target/lib/systemd/system-shutdown/ts3000_restart.sh
fi

grep LS4 /proc/device-tree/model > /dev/null
is_ls400=$?
grep TS12 /proc/device-tree/model > /dev/null
is_ts1200=$?
if [ $is_ls400 -eq 0 ] || [ $is_ts1200 -eq 0 ]; then
      cp /source/ls400_restart.sh /target/lib/systemd/system-shutdown/
      chmod 755 /target/lib/systemd/system-shutdown/ls400_restart.sh
fi
