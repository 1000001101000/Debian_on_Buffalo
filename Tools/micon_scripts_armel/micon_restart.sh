#!/bin/bash
# place in /lib/systemd/system-shutdown/ for debian based systems
# other systems it's /usr/lib/systemd/system-shutdown/

if [ "$1" == "halt" ] || [ "$1" == "poweroff" ]; then
    /usr/local/bin/micon_scripts/micon_shutdown
else
    /usr/local/bin/micon_scripts/micon_restart
fi

exit 0

