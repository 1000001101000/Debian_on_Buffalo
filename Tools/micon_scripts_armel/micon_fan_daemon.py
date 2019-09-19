#!/usr/bin/python3

import libmicon
import subprocess
import time
import sys
import configparser
import os

config_file="/etc/micon_fan.conf"

config = configparser.ConfigParser()
if os.path.exists(config_file):
	config.read(config_file)
else:
	config['Rackmount'] = {'MediumTempC': '40', 'HighTempC': '50', 'ShutdownTempC': '65'}
	config['Desktop'] = {'MediumTempC': '25', 'HighTempC': '35', 'ShutdownTempC': '65'}
	with open(config_file, 'w') as configfile:
		config.write(configfile)

if len(sys.argv) > 1:
	debug=str(sys.argv[1])
else:
	debug=""

##try reading micon version from each port to determine the right one
for port in ["/dev/ttyS1","/dev/ttyS3"]:
	test = libmicon.micon_api(port)
	version = test.send_read_cmd(0x83)
	test.port.close()
	if version:
		break

version=version.decode('utf-8')

if ((version.find("TS-RXL") != -1) or (version.find("TS-MR") != -1) or (version.find("1400R") != -1)):
	med_temp=int(config['Rackmount']['MediumTempC'])
	high_temp=int(config['Rackmount']['HighTempC'])
	shutdown_temp=int(config['Rackmount']['ShutdownTempC'])
else:
	med_temp=int(config['Desktop']['MediumTempC'])
	high_temp=int(config['Desktop']['HighTempC'])
	shutdown_temp=int(config['Desktop']['ShutdownTempC'])

if debug == "debug":
	print("Terastation Version: ",version," Medium Temp: ",med_temp,"C"," High Temp: ",high_temp,"C")

while True:
	try:
		test = libmicon.micon_api(port)
		micon_temp=int.from_bytes(test.send_read_cmd(0x37),byteorder='big')
		##set speed based on thresholds
		fan_speed=1
		if micon_temp > med_temp:
			fan_speed=2
		if micon_temp > high_temp:
			fan_speed=3
		if micon_temp > shutdown_temp:
                        os.system('systemctl poweroff')
		test.send_write_cmd(1,0x33,fan_speed)
		if debug == "debug":
			print("Fan Speed ",fan_speed," Temperature ",micon_temp,"C")

		current_speed=int.from_bytes(test.send_read_cmd(0x33),byteorder='big')
		if current_speed==0:
			print("Fan Stopped!")
			test.set_lcd_buffer(libmicon.lcd_set_buffer0,"Warning:","Fan Stopped!!!!")
			test.cmd_force_lcd_disp(libmicon.lcd_disp_buffer0)
			test.set_lcd_color(libmicon.LCD_COLOR_RED)
			test.set_lcd_brightness(libmicon.LCD_BRIGHT_FULL)
			test.cmd_sound(libmicon.BZ_MUSIC2)

		test.port.close()
	except:
		print("Fan get/set failed, retrying")
		time.sleep(10)
		continue
	else:
		time.sleep(120)
quit()
