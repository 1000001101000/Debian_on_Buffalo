# Debian_on_Buffalo
Tools for Installing/Running Debian on Buffalo Linkstation/Terastation (LS4XX, LS2XX, TS1XXX and TS3X00) 

My goal is to make it possible for someone with fairly basic linux knowledge to install Debian on their Marvell Armada based Buffalo Linkstation/Terastation similarly to what is provided for the older generation orion5x/Kirkwood devices.

This process:
- Does not make any changes to the device itself.
- Works on devices running the latest firmware.
- Uses network-console installer provided by Debian.
- Does not require compiling/maintaining a custom kernel.
- Does not require deleting the data stored on the device.
***That said, always backup your data before proceeding.

I've divided the process into 5 parts:

1. Download my prebuilt installer images or build your own (my build scripts are in the /build directory)
2. Transfer the installer image to the device.
3. Run the Debian Installer.
4. Install/configure the system to make use of the hardware (fan/tempurature sensors/etc)

My goal has been to make this process as easy as possible while also providing all the information someone would need to customize/expand this process to fit their needs.

Feel free to contact me with any questions/feedback.

Disclaimer: While this process does not modify the actual device and cannot "brick" your device, if something goes wrong (like skipping a step) it may be necessary remove a drive from the device and connect to a PC to recover. 


Acknowledgments: 

Toha     - https://github.com/tohenk/linkstation-mod

rogers0  - https://github.com/rogers0/OpenLinkstation

shihsung - https://sites.google.com/site/shihsung/


