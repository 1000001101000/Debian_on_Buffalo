#!/usr/bin/python3

import libmicon
import time
import sys

##try reading micon version from each port to determine the right one
for port in ["/dev/ttyS1"]:
        test = libmicon.micon_api(port)
        micon_version = test.send_read_cmd(0x83)
        if micon_version:
                break
        test.port.close()

test.send_write_cmd(0,0x0F)
test.send_write_cmd(0,0x0F)

test.port.close()
quit()
