depmod
/usr/sbin/rngd -f -r /dev/urandom&
rng_pid=$!
sleep 10
kill $rng_pid


##special stuff for terastations with mcu
if [ "$(/source/micro-evtd -s 0003 | tail -n 1)" == "0" ]; then
   micon_version="$(/source/micro-evtd -s 8083)"
   ## diable startup watchdog
   /source/micro-evtd -s 0003

   ##clear alert leds if any set power led
   /source/micro-evtd -s 0250090f96,02520000ac,02510d00a0

   ## set lcd display to installer message
   /source/micro-evtd -s 20905465726173746174696f6e2061726d2044656269616e20496e7374616c6c657231,0025,013220,013aff

   ##clear alert leds if any set power led
   /source/micro-evtd -s 0250090f96,02520000ac,02510d00a0

  ## if not a ts2pro try changing the lcd color
  echo $micon_version | grep HTGL
  if [ $? -ne 0 ]; then
     /source/micro-evtd -s 02500007,02510006
  fi

  ##if device is rack mount set fan to medium (still loud) otherwise set high
  echo $micon_version | grep 'TS-RXL\|RHTGL\|TS-MR\|TS1400R'
  if [ $? -ne 0 ]; then
    /source/micro-evtd -s 013303
  else
    /source/micro-evtd -s 013302
  fi

fi

exit 0
