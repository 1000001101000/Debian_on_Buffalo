#!/usr/bin/python3

import libmicon
import platform


###make miconv2 and v3 start up tasks functions.

def startupV2(port):
	test = libmicon.micon_api(port)

	micon_version = test.send_read_cmd(0x83)
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

def startupV3(port):
	test = libmicon.micon_api_v3(port)

	##disable watchdog
	test.send_miconv3("BOOT_END")

	file = open("/etc/debian_version", "r")
	version= "Debian " + file.readline().strip()
	version = version.center(16,u"\u00A0")
	title = "Terastation " + platform.machine()[:3].upper()

	print(test.set_lcd(0,title))
	print(test.set_lcd(1,version))

	##solid power LED
	test.set_led(0,"on")
	test.port.close()

# check for some sort of config file to avoid messing with ports each time?

##try reading micon version from each port to determine the right one
for port in ["/dev/ttyS1","/dev/ttyS3"]:
	try:
		test = libmicon.micon_api(port)
	except:
		continue
	micon_version = test.send_read_cmd(0x83)
	if micon_version:
		test.port.close()
		startupV2(port)
		quit()
	test.port.close()


for port in ["/dev/ttyUSB0","/dev/ttyS1","/dev/ttyS0"]:
	try:
		test = libmicon.micon_api_v3(port)
	except:
		continue
	micon_version = test.send_miconv3("VER_GET")
	if micon_version:
		test.port.close()
		startupV3(port)
		quit()
	test.port.close()

quit()
