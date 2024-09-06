# Introduction
Its a small shell script for mac which is used to rip ps2 CD/DVD discs and saves as iso file. Its working is similar to ImgBurn on windows. The created ISO file can be recognized by OPL directly or any emulator.
By Default running rip_ps2_disc.sh will use /dev/disk2 as default DVD/CD/ROM drive to copy ps2 files from and it will dump the iso to current user's desktop. You can provide different input disk location and output path as well.
In the back-end, it simply uses dd command to dump disc to iso and pv command to show progress.

# Pre-requisities
* It requires pv package to be installed in order to show copy progress.

# IMPORTANT NOTE
Please double check your disk drive name from Disk Utility Device Section. It will dump when the disk is unmounted.

# Usage
Make sure to mark file as executable first. To see help type
```shell
./rip_ps2_disc.sh --help
```

# Example
```shell
./rip_ps2_disc.sh --if /dev/disk2 --of ~/Desktop/nfs.iso --bs 6m
```
It will ask for a confirmation. Type "yes" completely to confirm to start the process. Wait about 20-30 minutes depending upon the size of game and copy speed, it will take a while.

# Credits
Its written by Tahir Zia, I take no liability incase of any damage or error this script can do. You can open the script file in any editor to review and see what commands are being executed.
Thankyou
