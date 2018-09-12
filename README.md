# Debian_on_Buffalo
Tools for Installing/Running Debian on Buffalo Linkstation/Terastation (LS4XX, LS2XX, TSXXX etc) 

My goal is to make it possible for someone with fairly basic linux knowledge to install Debian on their Marvell Armada based Buffalo Linkstation/Terastation similarly to what is provided for the older generation orion5x/Kirkwood devices.


I've divided the process into 5 parts:

1. Obtain the Device Tree Blob (DTB) for your device.
2. Use the DTB and the kernel/initrd provided by Debian to create the installer image.
3. Transfer the installer image to the device.
4. Run the Debian Installer.
5. Install/configure the system to make use of the hardware (fan/tempurature sensors/etc)

Each section includes "the easy way" which is aimed at being simpler and requiring less technical knowledge by using files I've already created, and "the hard way" which shows how to compile your own files relying on as few resources provided by me as possible.
 
Feel free to contact me with any questions/feedback.

Acknowledgments:
Toha     - https://github.com/tohenk/linkstation-mod
rogers0  - https://github.com/rogers0/OpenLinkstation
shihsung - https://sites.google.com/site/shihsung/
