# Debian_on_Buffalo
Tools for Installing/Running Debian on all ARM-based Buffalo Linkstation/Terastation devices.

If this project helps you click the Star at the top of the page to let me know! If you'd like to contribute to the continued development/maintenance consider clicking on the sponsor button.

In addition to the Issues and Discussions tabs on GitHub we now also have a Discord channel at https://discord.gg/E88dkcuyW4 or our IRC on Libera.Chat in the #miraheze-buffalonas channel!

If you'd like to help support the project consider donating via the sponsor button above. 

<br>

## Quick Note about Debian Trixie:

All devices should be able to run Trixie using the files provided by this project but the ssh netinstaller images are limited to the armhf devices. This is because Debian has discontinued their armel installer starting with Trixie and have annouced that Trixie will be the last version of Debian with armel support. 

For now this just means that the "debootstrap" method is the only way to install the latest Debian version on the oldest devices. I've spent some time this cycle re-working that process to make it more reliable and easier to use so that it can take over as the primary way to perform the installs moving forward. 

I've also started another project based on the Buildroot project which provides a method for building custom firmware images for Buffalo devices similar to how images are built for routers and other embedded linux devices. That project supports all the devices including any without Debian support. 
More information can be found at https://github.com/1000001101000/Buildroot_for_Buffalo



I've moved all the documentation to the wiki:
https://github.com/1000001101000/Debian_on_Buffalo/wiki
 


