#!/usr/bin/python3

import libmicon
import time
import sys

##try reading micon version from each port to determine the right one
for port in ["/dev/ttyS1","/dev/ttyS3"]:
        test = libmicon.micon_api(port)
        micon_version = test.send_read_cmd(0x83)
        if micon_version:
                break
        test.port.close()

micon_version=micon_version.decode('utf-8')

if sys.argv[1] in ["halt","poweroff"]:
	test.set_lcd_buffer(0x90,"     ","     ")
	test.cmd_force_lcd_disp(libmicon.lcd_disp_buffer0)
	test.set_lcd_brightness(libmicon.LCD_BRIGHT_OFF)

test.send_write_cmd(1,0x35, 0x00)
test.send_write_cmd(0,0x03)
test.send_write_cmd(0,0x0C)

if sys.argv[1] in ["halt","poweroff"]:
	if (micon_version.find("TS-XEL") != -1):
		test.send_write_cmd(1,0x46,0x00)
		test.send_write_cmd(0,0x0E)
	else:
		test.send_write_cmd(0,0x06)
else:
	test.send_write_cmd(1,0x46,0x18)
	test.send_write_cmd(0,0x0E)

time.sleep(5)
test.port.close()
quit()
