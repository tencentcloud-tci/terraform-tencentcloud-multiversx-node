#!/bin/bash

vol="$1" #pass the disk parameter to the script (e.g vdb, vdc, ..)
mdisk="/dev/${vol}"
pdisk="/dev/${vol}1"
mtarget="/data/${vol}"
ptarget="/data/${vol}/${vol}1"


#create target directories
mkdir $mtarget
mkdir $ptarget

#partition disk
sudo mkfs -t ext4 $mdisk
echo -e "n\np\n1\n\nw" | fdisk $mdisk
sudo partprobe $mdisk

#format  volume
sudo mkfs -t ext4 $pdisk
sudo mount $pdisk $ptarget

#adding volume to fstab
uuid=`udevadm info -q all -n $pdisk | grep -m1 uuid | cut -b 17-` #get the disk uuid
line=`echo "UUID=$uuid $ptarget ext4 defaults 0 2"` #create disk entry line
echo $line >> /etc/fstab #append disk mountpoint
echo "" >> /etc/fstab #append new line to the end