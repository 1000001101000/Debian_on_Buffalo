#!/usr/bin/python3

import libmicon

##try reading micon version from each port to determine the right one
for port in ["/dev/ttyS1","/dev/ttyS3"]:
	test = libmicon.micon_api(port)
	result = test.send_read_cmd(0x83)
	if result:
                break
	test.port.close()

test.send_write_cmd(0,0x03)
test.port.close()

