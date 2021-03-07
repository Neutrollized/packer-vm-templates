#!/bin/bash
set +x

# pre-execution checks
if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
elif [[ $(/usr/sbin/swapon -s | wc -l) -gt 0 ]]; then
  echo "You already have a swap partition"
  exit 2
fi


# between 8G and 16G memory, swap should match memory
# more 16G memory, swap should be 16G
SWAP_SIZE="${1:-16G}"


echo '+ finding device name' 
# I do this to bypass the unicode character in the output of lsblk sometimes
for i in $(lsblk -o NAME,SIZE | grep ${SWAP_SIZE} | awk '{ print $1 }' | sort); do
  echo ${i} | tail -c 5 | head -c 3 >> /tmp/lsblk_swapdev.txt
  echo '' >> /tmp/lsblk_swapdev.txt
done

SWAP_DEV=$(uniq -u /tmp/lsblk_swapdev.txt)

echo ' + partitioning device' 
/usr/sbin/parted --align optimal /dev/${SWAP_DEV} \
  mklabel msdos \
  mkpart primary linux-swap 0% 100%

echo ' + making swap device' 
sleep 3
/usr/sbin/mkswap /dev/${SWAP_DEV}1

echo ' + enabling swap device' 
sleep 3
/usr/sbin/swapon /dev/${SWAP_DEV}1


echo '+ getting device uuid' 
sleep 3
SWAP_DEV_UUID=$(ls -lha /dev/disk/by-uuid | grep ${SWAP_DEV}1 | awk '{ print $9 }')
echo "UUID: ${SWAP_DEV_UUID}"

echo ' + adding entry in /etc/fstab' 
echo "UUID=${SWAP_DEV_UUID}  swap  swap  defaults  0 0" >> /etc/fstab


echo '+ complete!' 
rm /tmp/lsblk_swapdev.txt
exit 0
