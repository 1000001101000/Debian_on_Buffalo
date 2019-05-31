#!/usr/bin/python3

import libmicon

test = libmicon.micon_api("/dev/ttyS1")

test.send_write_cmd(0,0x03)

