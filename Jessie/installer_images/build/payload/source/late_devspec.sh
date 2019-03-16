##special stuff for ts3000
grep TS3 /proc/device-tree/model > /dev/null
if [ $? -eq 0 ]; then
	cp -r /source/dist/ts3000_startup/ "/target/usr/local/bin/"
	cp /source/*.service /target/etc/systemd/system/
fi
