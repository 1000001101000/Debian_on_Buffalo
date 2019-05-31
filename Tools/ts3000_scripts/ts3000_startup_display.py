#!/usr/bin/python3

import libmicon
import platform

file = open("/etc/debian_version", "r")
version= "Debian " + file.readline().strip()
version = version.center(16)
title = "Terastation " + platform.machine()[:3].upper()

test = libmicon.micon_api("/dev/ttyS1")

##set custom lcd message
test.set_lcd_buffer(libmicon.lcd_set_buffer0,title,version)
test.cmd_force_lcd_disp(libmicon.lcd_disp_buffer0)
test.send_write_cmd(1,libmicon.lcd_set_dispitem,0x20)
test.send_write_cmd(1,libmicon.lcd_set_dispitem_ex,0x00)
test.send_write_cmd(0,libmicon.lcd_changemode_button)

test.set_lcd_brightness(libmicon.LCD_BRIGHT_FULL)
test.set_lcd_color(libmicon.LCD_COLOR_AQUA)

test.cmd_set_led(libmicon.LED_OFF,[0xFF,0x00])
test.cmd_set_led(libmicon.LED_ON,libmicon.POWER_LED)

test.port.close()
#quit()
