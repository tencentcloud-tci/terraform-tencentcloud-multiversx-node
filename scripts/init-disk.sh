#!/bin/bash

vol="$1" #pass the disk parameter to the script (e.g vdb, vdc, ..)
mdisk="/dev/${vol}"
pdisk="/dev/${vol}1"
mtarget="/data/${vol}"
ptarget="/data/${vol}/${vol}1"

#colors
BLUE='\033[1;34m'
GREY='\033[0;37m'

#create target directories
sudo echo -e "${BLUE}Creating folders ${GREY}..."
sudo mkdir $mtarget
sudo mkdir $ptarget

#partition disk
sudo echo -e "${BLUE}Formatting disk $mdisk ${GREY}..."
sudo mkfs -t ext4 $mdisk
sudo echo -e "${BLUE}Partitioning disk $mdisk ${GREY}..."
sudo echo -e "n\np\n1\n\n\nw\n" | fdisk $mdisk
sudo echo -e "${BLUE}Sync partition table of $mdisk to OS ${GREY}..."
sudo partprobe $mdisk

#format  volume
sudo echo -e "${BLUE}Formatting volume $pdisk ${GREY}..."
sudo mkfs -t ext4 $pdisk
sudo echo -e "${BLUE}Mounting volume $pdisk to $ptarget ${GREY}..."
sudo mount $pdisk $ptarget

#adding volume to fstab
uuid=`sudo blkid $pdisk | cut -d '"' -f2`  #get the disk uuid
line=`echo "UUID=$uuid $ptarget ext4 defaults 0 2"` #create disk entry line
sudo echo $line >> /etc/fstab #append disk mountpoint
sudo echo -e "${BLUE}Adding volume $pdisk to boot ${GREY}..."
sudo echo "" >> /etc/fstab #append new line to the end