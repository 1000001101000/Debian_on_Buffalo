##special stuff for ts3000
grep TS3 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
	/source/ts3000_scripts/ts3000_installer_display
	/source/ts3000_scripts/ts3000_startup
fi

grep TS14 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
        /source/ts3000_scripts/ts3000_installer_display
        /source/ts3000_scripts/ts3000_startup
fi

exit 0
