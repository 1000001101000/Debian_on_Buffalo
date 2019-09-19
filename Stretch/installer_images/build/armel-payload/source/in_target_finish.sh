##special stuff for terastations with mcu
grep Teras /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
        systemctl enable micon_boot.service
        systemctl enable micon_lcd.service
	systemctl enable micon_fan_daemon.service
fi

exit 0
