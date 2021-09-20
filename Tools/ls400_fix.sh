all_leds="$(ls /sys/class/leds)"

clear_leds()
{
  for led in $all_leds
  do
    echo 0 > /sys/class/leds/$led/brightness
  done
}

blink_fail()
{
  echo "failed to update flash but no changes were made"
  leds="$(ls /sys/class/leds/ | grep "orange\|amber")"
  clear_leds
  for led in $leds
  do
    echo 1 > /sys/class/leds/$led/brightness
  done
  exit 0
}

blink_emergency()
{
  leds="$(ls /sys/class/leds/ | grep "red")"
  clear_leds
  for led in $leds
  do
    echo 1 > /sys/class/leds/$led/brightness
  done
  exit 0
  ##don't shutdown, it might not be bootible
  ##ask for help manually troubleshooting
}

blink_success()
{
  leds="$(ls /sys/class/leds/ | grep "white")"
  clear_leds
  for led in $leds
  do
    echo 1 > /sys/class/leds/$led/brightness
  done
  echo "shutting down"
}

serial="$(/source/fw_printenv SerialNo)"

if [ -z "$serial" ]; then
  echo "Serial lookup failed, dtb flash configuration probably bad"
  blink_fail
  exit 0
fi

mtddev="$(grep mtd /etc/fw_env.config | cut -d " " -f 1)"

model="$(hexdump $mtddev -s 0x000ffc30 -n 5 -e '"%c"')"

if [ "$model" == "LS410" ] || [ "$model" == "LS420" ] || [ "$model" == "LS421" ]; then
  echo "supported model found ($model), continuing"
else
  echo "could not confim model supported LS410/LS420/LS421 quitting..."
  blink_fail
  exit 0
fi

dd if=$mtddev of=backup.img bs=4k 2> /dev/null
if [ $? -ne 0 ]; then
  echo "flash backup failed, quitting"
  blink_fail
  exit 0
fi

mtdhash="$(md5sum $mtddev | cut -d " " -f 1)"
bakhash="$(md5sum backup.img | cut -d " " -f 1)"

if [ "$mtdhash" != "$bakhash" ]; then
  echo "backup hash doesn't match device hash, quitting"
  blink_fail
  exit 0
fi

echo "attempting to replace firmware"

realdev="$(echo $mtddev | cut -d "k" -f 2)"
flashcp -v /source/u-boot.buffalo-1.34_voodoo /dev/mtd$realdev

if [ $? -ne 0 ]; then
  echo "flash reported fail, attempting to restore original"
  mtdhash="$(md5sum $mtddev | cut -d " " -f 1)"
  if [ "$mtdhash" == "$bakhash" ]; then
    echo "mtd hash still matches backup, no changes made"
    blink_fail
    exit 0
  else
    echo "attempting to restore flash from backup"
    flashcp -v backup.img /dev/mtd$realdev
    mtdhash="$(md5sum $mtddev | cut -d " " -f 1)"
    if [ "$mtdhash" == "$bakhash" ]; then
      echo "mtd hash matches backup, no changes made"
      blink_fail
      exit 0
    else
      echo "failed to restore flash, device might not be in a bootible state!!"
      blink_emergency
      exit 0
    fi
  fi
else
  echo "update succeeded!"
  blink_success
  exit 0
fi

exit 0
