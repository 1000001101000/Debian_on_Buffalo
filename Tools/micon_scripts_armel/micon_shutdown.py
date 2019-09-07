#!/usr/bin/python3

import libmicon
import time

##try reading micon version from each port to determine the right one
for port in ["/dev/ttyS1","/dev/ttyS3"]:
        test = libmicon.micon_api(port)
        result = test.send_read_cmd(0x83)
        if result:
                break
        test.port.close()

test.set_lcd_buffer(libmicon.lcd_set_buffer0,"     ","     ")
test.cmd_force_lcd_disp(libmicon.lcd_disp_buffer0)
test.set_lcd_brightness(libmicon.LCD_BRIGHT_OFF)

test.send_write_cmd(1,0x35, 0x00)
test.send_write_cmd(0,0x03)
test.send_write_cmd(0,0x0C)

test.send_write_cmd(0,0x06)
test.port.close()
time.sleep(10)

