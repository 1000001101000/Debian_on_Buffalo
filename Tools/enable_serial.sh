#!/bin/sh
PREREQ=""
prereqs()
{
     echo "$PREREQ"
}

case $1 in
prereqs)
     prereqs
     exit 0
     ;;
esac

mkdir -p "/usr/local/bin/"
cp "/sbin/micro-evtd" "/usr/local/bin/"

micro_exe="/usr/local/bin/micro-evtd"
if [ "$($micro_exe -s 0003 | tail -n 1)" = "0" ]; then
   micon_version="$($micro_exe -s 8083)"
   ## diable startup watchdog
   $micro_exe -s 0003 > /dev/null

   ##clear alert leds if any set power led
   $micro_exe -s 0250090f96,02520000ac,02510d00a0 > /dev/null

   ##clear alert leds if any set power led
   $micro_exe -s 0250090f96,02520000ac,02510d00a0 > /dev/null

  ## if not a ts2pro try enabling console.
  echo $micon_version | grep HTGL > /dev/null
  if [ $? -eq 0 ]; then
     $micro_exe -s 000f > /dev/null
  fi

  echo "micon serial console enabled." > /dev/ttyS0

fi

###otherwise... load some modules for usbtty? probably use normal module process for that.
