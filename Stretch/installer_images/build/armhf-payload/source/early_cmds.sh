
##run micon startup scripts if needed
grep TS3 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
	/source/micon_scripts/micon_installer_display
	/source/micon_scripts/micon_startup
fi

grep TS14 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
        /source/micon_scripts/micon_installer_display
        /source/micon_scripts/micon_startup
fi

exit 0
