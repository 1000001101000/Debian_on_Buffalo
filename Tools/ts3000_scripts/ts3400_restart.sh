#!/bin/bash
# place in /lib/systemd/system-shutdown/ for debian based systems
# other systems it's /usr/lib/systemd/system-shutdown/

if [ "$1" == "halt" ] || [ "$1" == "poweroff" ]; then
    /usr/local/bin/ts3000_scripts/ts3000_shutdown
fi

exit 0

