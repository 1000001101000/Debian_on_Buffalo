##special stuff for ts3000
grep TS3 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
	/source/dist/ts3000_startup/installer_display
	/source/dist/ts3000_startup/ts3000_startup
fi
