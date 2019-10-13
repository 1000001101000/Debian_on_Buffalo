##special stuff for ts3000
grep TS3 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
        systemctl enable micon_boot.service
        systemctl enable init_lcd.service
	systemctl enable micon_fan_daemon.service
fi

grep TS14 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
        systemctl enable micon_boot.service
	systemctl enable micon_fan_daemon.service
fi

exit 0
