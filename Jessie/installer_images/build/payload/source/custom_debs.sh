dpkg -i --force-depends /tmp/*.deb > /tmp/dpkg.log 2>&1
rm /tmp/*.deb
rm /tmp/*.sh
