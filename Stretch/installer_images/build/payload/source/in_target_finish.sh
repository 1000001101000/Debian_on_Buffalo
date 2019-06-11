##special stuff for ts3000
grep TS3 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
        systemctl enable ts3000_boot.service
        systemctl enable init_lcd.service
fi

grep TS14 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
        systemctl enable ts3000_boot.service
        systemctl enable init_lcd.service
fi

exit 0
