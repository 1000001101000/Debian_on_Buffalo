##special stuff for devices with microcontroller
if [ "$(/source/micro-evtd -s 0003 | tail -n 1)" == "0" ]; then
        cp -r /source/micon_scripts "/target/usr/local/bin/"
        cp /source/micon_scripts/*.service /target/etc/systemd/system/
        cp /source/micon_scripts/micon_shutdown.py /target/lib/systemd/system-shutdown/
        chmod 755 /target/lib/systemd/system-shutdown/micon_shutdown.py
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
