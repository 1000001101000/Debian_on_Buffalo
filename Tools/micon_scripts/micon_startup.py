#!/usr/bin/python3

import libmicon
import platform

##try reading micon version from each port to determine the right one
for port in ["/dev/ttyS1","/dev/ttyS3"]:
        test = libmicon.micon_api(port)
        micon_version = test.send_read_cmd(0x83)
        if micon_version:
                break
        test.port.close()

micon_version=micon_version.decode('utf-8')

##disable boot watchdog
test.send_write_cmd(0,0x03)

file = open("/etc/debian_version", "r")
version= "Debian " + file.readline().strip()
version = version.center(16)
title = "Terastation " + platform.machine()[:3].upper()

### need to understand variations of this
##turn of red drive leds
test.cmd_set_led(libmicon.LED_OFF,[0x00,0x0F])

test.set_lcd_buffer(0x90,title,version)
test.cmd_force_lcd_disp(libmicon.lcd_disp_buffer0)
test.send_write_cmd(1,libmicon.lcd_set_dispitem,0x20)
test.set_lcd_brightness(libmicon.LCD_BRIGHT_FULL)

if (micon_version.find("HTGL") == -1):
	test.set_lcd_color(libmicon.LCD_COLOR_GREEN)

test.cmd_set_led(libmicon.LED_ON,libmicon.POWER_LED)

test.port.close()
quit()
