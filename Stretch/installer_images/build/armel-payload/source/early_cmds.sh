
##run micon startup scripts if needed
grep Tera /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
	/source/micon_scripts/micon_installer_display
	/source/micon_scripts/micon_startup
#	/source/micon_scripts/micon_fan_daemon &
fi

exit 0
