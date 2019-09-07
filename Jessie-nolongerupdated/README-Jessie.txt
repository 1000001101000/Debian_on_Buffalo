Debian Jessie reached end of life in 6/2018. There will still be "Long Term Support" through 6/2020 but many components have already been removed/archived from Debian's repositories (such as the installer images). I strongly recommend not installing Jessie going forward. 

Information about the lifecycle of Debian Versions can be found at:
https://wiki.debian.org/DebianReleases

Fans:
The Kernel that is provided with Debian Jessie does not include the gpio-fan driver. If you wish to use fancontrol you need to either re-complile the kernel to add gpio-fan support or compile and install the gpio-fan module seperately. I created a script to partially automate builing such modules which can be found at:
https://github.com/1000001101000/Debian_Module_Builder

Flash-Kernel:
To use DTB files that aren't part of the kernel package a newer version of flash-kernel than the one provided by Debian Jessie is required. I included the Jessie-Backports version as part of the installer to deal with this automatically.

