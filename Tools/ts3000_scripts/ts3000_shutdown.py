#!/usr/bin/python3

import libmicon

test = libmicon.micon_api("/dev/ttyS1")

##enable just the messages that we've configured so far.
test.set_lcd_buffer(libmicon.lcd_set_buffer0,"     ","     ")
test.cmd_force_lcd_disp(libmicon.lcd_disp_buffer0)

test.send_write_cmd(1,0x35, 0x00)
test.send_write_cmd(0,0x0C)
test.send_write_cmd(0,0x06)

test.port.close()
